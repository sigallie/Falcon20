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

using ViewReports;
using CrystalRpts;
using DBUtils;

namespace Reports
{
    [System.Runtime.InteropServices.GuidAttribute("EEA36E16-2DB0-4D17-9CEA-1C3F0E25B3EE")]
    public partial class ViewCashBook : Form
    {
        public ViewCashBook()
        {
            InitializeComponent();
        }

        private void ViewCashBook_Load(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(DBUtils.ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select code from cashbooks where active = 'ACTIVE' order by code", conn);
                    SqlDataReader rd = cmd.ExecuteReader();

                    while (rd.Read())
                    {
                        cmbCashbook.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();
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

        private void btnView_Click(object sender, EventArgs e)
        {
            if(cmbCashbook.Text == "" || dtEnd.Text == "" || dtStart.Text == "")
            {
                MessageBox.Show("Insufficient details provided!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using (SqlConnection conn = new SqlConnection(DBUtils.ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("PopulateCashBook", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@cashbook", cmbCashbook.Text);
                    SqlParameter p2 = new SqlParameter("@start", dtStart.DateTime);
                    SqlParameter p3 = new SqlParameter("@end", dtEnd.DateTime);
                    SqlParameter p4 = new SqlParameter("@user", GenLib.ClassGenLib.username);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.ExecuteNonQuery();

                    CashBook bk = new CashBook();
                    bk.Parameters["cashbookname"].Value = cmbCashbook.Text;
                    bk.Parameters["sdate"].Value = dtStart.Text;
                    bk.Parameters["edate"].Value = dtEnd.Text;
                    bk.Parameters["user"].Value = GenLib.ClassGenLib.username;
                    ((SqlDataSource)bk.DataSource).ConfigureDataConnection += ViewCashBook_ConfigureDataConnection;

                    ReportPrintTool tool = new ReportPrintTool(bk);
                    tool.ShowPreview();       

                    //CrystalForm rpts = new CrystalForm("Cashbook - " + cmbCashbook.Text, "", "", dtStart.DateTime, dtEnd.DateTime);
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
            }
        }

        private void ViewCashBook_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
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
