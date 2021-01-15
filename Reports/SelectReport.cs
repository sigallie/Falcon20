using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;
using DevExpress.XtraReports.UI;
using DevExpress.DataAccess.ConnectionParameters;
using DevExpress.DataAccess.Sql;


using DBUtils;
using GenLib;
using ViewReports;
using CrystalRpts;

namespace Reports
{
    public partial class SelectReport : Form
    {
        int ledger = 0;
        string ClientNo = "";
        public SelectReport(int lg)
        {
            InitializeComponent();
            ledger = lg;
        }

        private void SelectReport_Load(object sender, EventArgs e)
        {
            for (int i = 0; i < xtraTabControl1.TabPages.Count; i++ )
            {
                xtraTabControl1.TabPages[i].PageVisible = false;
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    if (ledger == 1)
                    {
                        this.Text = "View Ledger";
                        tbLedgers.PageVisible = true;

                        SqlCommand cmd = new SqlCommand("select ledgername from LedgerAccount order by ledgername", conn);
                        SqlDataReader rd = cmd.ExecuteReader();
                        while(rd.Read())
                        {
                            cmbLedger.Properties.Items.Add(rd[0].ToString());
                        }
                        rd.Close();
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnViewLedger_Click(object sender, EventArgs e)
        {
            if(cmbLedger.Text == "" && (chkAll.Checked == false))
            {
                MessageBox.Show("Please select the Ledger to display!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    if (chkAll.Checked == false)
                    {
                        string strSQL = "select ledgercode from LedgerAccount where ledgername like '" + cmbLedger.Text + "%'";
                        SqlCommand cmdClient = new SqlCommand(strSQL, conn);
                        string code = cmdClient.ExecuteScalar().ToString();

                        SqlCommand cmd = new SqlCommand("PopulateLedger2", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandTimeout = 5000;
                        SqlParameter p1 = new SqlParameter("@Login", ClassGenLib.username);
                        SqlParameter p2 = new SqlParameter("@ClientNo", code);
                        SqlParameter p3 = new SqlParameter("@StartDate", dtStart.DateTime.Date);
                        SqlParameter p4 = new SqlParameter("@EndDate", dtEnd.DateTime.Date);

                        cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                        cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);

                        cmd.ExecuteNonQuery();

                        LedgerReport rptLedger = new LedgerReport();
                        rptLedger.Parameters["start"].Value = dtStart.Text;
                        rptLedger.Parameters["end"].Value = dtEnd.Text;
                        rptLedger.Parameters["ledger"].Value = cmbLedger.Text;
                        rptLedger.Parameters["username"].Value = ClassGenLib.username;
                        ((SqlDataSource)rptLedger.DataSource).ConfigureDataConnection += SelectReport_ConfigureDataConnection;

                        ReportPrintTool tool = new ReportPrintTool(rptLedger);
                        tool.ShowPreview();
                    }
                    else
                    {
                        SqlCommand cmd1 = new SqlCommand("spConsolidatedCharges", conn);
                        cmd1.CommandType = CommandType.StoredProcedure;
                        SqlParameter p1 = new SqlParameter("@start", dtStart.Text);
                        SqlParameter p2 = new SqlParameter("@end", dtEnd.Text);
                        SqlParameter p3 = new SqlParameter("@user", ClassGenLib.username);

                        cmd1.Parameters.Add(p1);
                        cmd1.Parameters.Add(p2);
                        cmd1.Parameters.Add(p3);
                        cmd1.ExecuteNonQuery();

                        ConsildatedCharges cchgs = new ConsildatedCharges();
                        cchgs.Parameters["start"].Value = dtStart.Text;
                        cchgs.Parameters["end"].Value = dtEnd.Text;
                        ((SqlDataSource)cchgs.DataSource).ConfigureDataConnection += SelectReport_ConfigureDataConnection;

                        ReportPrintTool tool = new ReportPrintTool(cchgs);
                        tool.ShowPreview();
                    }

                    //CrystalForm rpts = new CrystalForm("Ledger - " + cmbLedger.Text, "", "", dtStart.DateTime, dtEnd.DateTime);
                    //rpts.ShowDialog();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }

                chkAll.Enabled = true;
            }
        }

        private void cmbLedger_SelectedValueChanged(object sender, EventArgs e)
        {
            if (cmbLedger.Text == "S.E.C. LEVY")
            {
                ClientNo = "156";
            }
            else if (cmbLedger.Text == "VALUE ADDED TAX (VAT)")
            {
                ClientNo = "151";
            }
            else if (cmbLedger.Text == "INVESTOR PROTECTION LEVY")
            {
                ClientNo = "155";
            }
            else if (cmbLedger.Text == "CAPITAL GAINS WITHHOLDING TAX")
            {
                ClientNo = "154";
            }
            else if (cmbLedger.Text == "STAMP DUTY (TAX)")
            {
                ClientNo = "152";
            }
            else if (cmbLedger.Text == "ZSE LEVY")
            {
                ClientNo = "153";
            }
            else if (cmbLedger.Text == "NMI REBATE ")
            {
                ClientNo = "157";
            }
            else if (cmbLedger.Text == "COMMISSION")
            {
                ClientNo = "150";
            }
            else if (cmbLedger.Text == "BASIC CHARGE")
            {
                ClientNo = "158";
            }
            else if (cmbLedger.Text.Trim() == "CSD LEVY")
            {
                ClientNo = "159";
            }
        }

        private void chkAll_Click(object sender, EventArgs e)
        {
         /*   if(chkAll.Checked == true)
            {
                cmbLedger.Enabled = false;
                cmbLedger.Text = "";
            }
            else
            {
                cmbLedger.Enabled = true;
            }*/
        }

        private void chkAll_CheckedChanged(object sender, EventArgs e)
        {
            if (chkAll.Checked == true)
            {
                cmbLedger.Enabled = false;
                cmbLedger.Text = "";
            }
            else
            {
                cmbLedger.Enabled = true;
            }
        }

        private void SelectReport_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
        {
            string ip = ""; string db = ""; string dbuser = ""; string dbpass = "";
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select dbserverip, dbname, dbusername, dbpassword from tblSystemParams", conn);
                    SqlDataReader rd = cmd.ExecuteReader();

                    while (rd.Read())
                    {
                        ip = rd[0].ToString();
                        db = rd[1].ToString();
                        dbuser = rd[2].ToString();
                        dbpass = rd[3].ToString();
                    }
                    rd.Close();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Failed to connect to database! " + ex.Message);
                }
            }

            e.ConnectionParameters = new MsSqlConnectionParameters(ip, db, dbuser, dbpass, MsSqlAuthorizationType.SqlServer);
        }
    }
}
