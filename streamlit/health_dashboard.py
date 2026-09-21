import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from snowflake.sqlalchemy import URL
from sqlalchemy import create_engine

# ── Page config ──────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="Health360 Dashboard",
    page_icon="🏥",
    layout="wide",
)

# ── Snowflake connection ──────────────────────────────────────────────────────
@st.cache_resource
def get_engine():
    return create_engine(URL(
        account   = "CHNAFLS-ZSB47658",
        user      = "SAIPRASANTH",
        password  = "Ravikumar1981@#",
        role      = "HEALTH_DWH_ROLE",
        warehouse = "TRANSFORM_WH",
        database  = "HEALTH360_PROJECT",
    ))

@st.cache_data(ttl=300)
def query(sql: str) -> pd.DataFrame:
    engine = get_engine()
    with engine.connect() as conn:
        df = pd.read_sql(sql, conn)
        df.columns = df.columns.str.upper()
        return df

# ── Sidebar navigation ────────────────────────────────────────────────────────
st.sidebar.image("https://img.icons8.com/color/96/hospital.png", width=80)
st.sidebar.title("Health360")
page = st.sidebar.radio(
    "Navigate",
    ["Overview", "Patient 360", "Cost Metrics", "Readmissions"],
)

# ═════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ═════════════════════════════════════════════════════════════════════════════
if page == "Overview":
    st.title("🏥 Health360 — Executive Overview")

    kpi = query("""
        select
            count(distinct patient_id)   as total_patients,
            count(distinct encounter_id) as total_encounters,
            count(distinct facility_name) as total_facilities
        from MARTS.CLINICAL_OVERVIEW
    """)

    cost = query("""
        select
            sum(total_billed)   as total_billed,
            sum(total_paid)     as total_paid,
            avg(denial_rate_pct) as avg_denial_rate
        from MARTS.COST_METRICS
    """)

    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric("Patients",      f"{int(kpi['TOTAL_PATIENTS'][0]):,}")
    c2.metric("Encounters",    f"{int(kpi['TOTAL_ENCOUNTERS'][0]):,}")
    c3.metric("Facilities",    f"{int(kpi['TOTAL_FACILITIES'][0]):,}")
    c4.metric("Total Billed",  f"${cost['TOTAL_BILLED'][0]:,.0f}")
    c5.metric("Denial Rate",   f"{cost['AVG_DENIAL_RATE'][0]:.1f}%")

    st.divider()
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Encounters by Type")
        enc_type = query("""
            select encounter_type, count(*) as encounters
            from MARTS.CLINICAL_OVERVIEW
            group by 1 order by 2 desc
        """)
        fig = px.pie(enc_type, names="ENCOUNTER_TYPE", values="ENCOUNTERS",
                     hole=0.4, color_discrete_sequence=px.colors.qualitative.Pastel)
        st.plotly_chart(fig, width='stretch')

    with col2:
        st.subheader("Encounters by State")
        by_state = query("""
            select state, count(*) as encounters
            from MARTS.CLINICAL_OVERVIEW
            group by 1 order by 2 desc limit 15
        """)
        fig = px.bar(by_state, x="STATE", y="ENCOUNTERS",
                     color="ENCOUNTERS", color_continuous_scale="Blues")
        st.plotly_chart(fig, width='stretch')

    st.subheader("Top 10 Diagnoses")
    diag = query("""
        select diagnosis_description, count(*) as cases
        from MARTS.CLINICAL_OVERVIEW
        where diagnosis_description is not null
        group by 1 order by 2 desc limit 10
    """)
    fig = px.bar(diag, x="CASES", y="DIAGNOSIS_DESCRIPTION", orientation="h",
                 color="CASES", color_continuous_scale="Teal")
    fig.update_layout(yaxis={"categoryorder": "total ascending"})
    st.plotly_chart(fig, width='stretch')

# ═════════════════════════════════════════════════════════════════════════════
# PATIENT 360
# ═════════════════════════════════════════════════════════════════════════════
elif page == "Patient 360":
    st.title("👤 Patient 360 View")

    patients = query("""
        select distinct patient_id, patient_name
        from MARTS.CLINICAL_OVERVIEW
        order by patient_name
    """)

    selected = st.selectbox(
        "Search patient",
        options=patients["PATIENT_ID"].tolist(),
        format_func=lambda pid: patients.loc[
            patients["PATIENT_ID"] == pid, "PATIENT_NAME"
        ].values[0],
    )

    if selected:
        info = query(f"""
            select *
            from MARTS.CLINICAL_OVERVIEW
            where patient_id = '{selected}'
            order by encounter_date desc
        """)

        if not info.empty:
            row = info.iloc[0]
            c1, c2, c3, c4 = st.columns(4)
            c1.metric("Name",   row["PATIENT_NAME"])
            c2.metric("Gender", row["GENDER"])
            c3.metric("DOB",    str(row["DOB"])[:10] if row["DOB"] else "—")
            c4.metric("Encounters", len(info))

            st.subheader("Encounter History")
            st.dataframe(
                info[[
                    "ENCOUNTER_ID", "ENCOUNTER_DATE", "ENCOUNTER_TYPE",
                    "LENGTH_OF_STAY", "PROVIDER_NAME", "FACILITY_NAME",
                    "DIAGNOSIS_CODE", "DIAGNOSIS_DESCRIPTION"
                ]].rename(columns=str.title),
                width='stretch',
                hide_index=True,
            )

            st.subheader("Length of Stay per Visit")
            fig = px.bar(info, x="ENCOUNTER_DATE", y="LENGTH_OF_STAY",
                         color="ENCOUNTER_TYPE",
                         color_discrete_sequence=px.colors.qualitative.Set2)
            st.plotly_chart(fig, width='stretch')

# ═════════════════════════════════════════════════════════════════════════════
# COST METRICS
# ═════════════════════════════════════════════════════════════════════════════
elif page == "Cost Metrics":
    st.title("💰 Cost & Claims Metrics")

    col1, col2 = st.columns(2)
    with col1:
        year_filter = st.selectbox("Year", [2022, 2023, 2024, 2025], index=2)
    with col2:
        state_list = query("select distinct state from MARTS.COST_METRICS order by 1")
        state_filter = st.multiselect("State", state_list["STATE"].tolist(),
                                      default=state_list["STATE"].tolist()[:5])

    states_str = ", ".join(f"'{s}'" for s in state_filter) if state_filter else "''"

    data = query(f"""
        select *
        from MARTS.COST_METRICS
        where year = {year_filter}
          and state in ({states_str})
    """)

    if not data.empty:
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("Total Billed",   f"${data['TOTAL_BILLED'].sum():,.0f}")
        c2.metric("Total Paid",     f"${data['TOTAL_PAID'].sum():,.0f}")
        c3.metric("Outstanding",    f"${data['TOTAL_OUTSTANDING'].sum():,.0f}")
        c4.metric("Denied Claims",  f"{int(data['DENIED_CLAIMS'].sum()):,}")

        st.divider()
        col1, col2 = st.columns(2)

        with col1:
            st.subheader("Billed vs Paid by Month")
            monthly = data.groupby("MONTH_NAME")[["TOTAL_BILLED", "TOTAL_PAID"]].sum().reset_index()
            month_order = ["January","February","March","April","May","June",
                           "July","August","September","October","November","December"]
            monthly["MONTH_NAME"] = pd.Categorical(monthly["MONTH_NAME"],
                                                    categories=month_order, ordered=True)
            monthly = monthly.sort_values("MONTH_NAME")
            fig = go.Figure()
            fig.add_bar(name="Billed", x=monthly["MONTH_NAME"], y=monthly["TOTAL_BILLED"],
                        marker_color="#4C8BF5")
            fig.add_bar(name="Paid",   x=monthly["MONTH_NAME"], y=monthly["TOTAL_PAID"],
                        marker_color="#34A853")
            fig.update_layout(barmode="group")
            st.plotly_chart(fig, width='stretch')

        with col2:
            st.subheader("Denial Rate by State")
            by_state = data.groupby("STATE")["DENIAL_RATE_PCT"].mean().reset_index()
            fig = px.bar(by_state, x="STATE", y="DENIAL_RATE_PCT",
                         color="DENIAL_RATE_PCT", color_continuous_scale="Reds",
                         labels={"DENIAL_RATE_PCT": "Denial Rate %"})
            st.plotly_chart(fig, width='stretch')

        st.subheader("Claims Detail")
        st.dataframe(
            data[[
                "FACILITY_NAME", "STATE", "YEAR", "MONTH_NAME", "GENDER",
                "TOTAL_CLAIMS", "TOTAL_BILLED", "TOTAL_PAID",
                "TOTAL_OUTSTANDING", "DENIAL_RATE_PCT"
            ]].rename(columns=str.title),
            width='stretch',
            hide_index=True,
        )

# ═════════════════════════════════════════════════════════════════════════════
# READMISSIONS
# ═════════════════════════════════════════════════════════════════════════════
elif page == "Readmissions":
    st.title("🔁 30-Day Readmission Dashboard")

    data = query("select * from MARTS.READMISSION_DASHBOARD")

    if data.empty:
        st.info("No 30-day readmission records found in the current dataset.")
    else:
        c1, c2, c3 = st.columns(3)
        c1.metric("Readmitted Patients", f"{data['PATIENT_ID'].nunique():,}")
        c2.metric("Total Readmissions",  f"{len(data):,}")
        c3.metric("Avg Days to Readmit", f"{data['DAYS_TO_READMIT'].mean():.1f}")

        st.divider()
        col1, col2 = st.columns(2)

        with col1:
            st.subheader("Readmissions by Gender")
            by_gender = data.groupby("GENDER").size().reset_index(name="COUNT")
            fig = px.pie(by_gender, names="GENDER", values="COUNT", hole=0.4,
                         color_discrete_sequence=px.colors.qualitative.Set3)
            st.plotly_chart(fig, width='stretch')

        with col2:
            st.subheader("Days to Readmission Distribution")
            fig = px.histogram(data, x="DAYS_TO_READMIT", nbins=30,
                               color_discrete_sequence=["#4C8BF5"],
                               labels={"DAYS_TO_READMIT": "Days to Readmit"})
            st.plotly_chart(fig, width='stretch')

        st.subheader("Readmission Records")
        st.dataframe(
            data[[
                "PATIENT_ID", "FULL_NAME", "GENDER", "DOB",
                "ENCOUNTER_DATE", "DISCHARGE_DATE", "LENGTH_OF_STAY",
                "READMIT_DATE", "DAYS_TO_READMIT"
            ]].rename(columns=str.title),
            width='stretch',
            hide_index=True,
        )
