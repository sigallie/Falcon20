using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

using DevExpress.Data;
using DevExpress.DataAccess;
using DevExpress.DataAccess.Sql;
using DevExpress.DataAccess.ConnectionParameters;
using DevExpress.XtraReports.UI;

using System.Data.SqlClient;
using DBUtils;
using GenLib;

namespace Reports
{
    public partial class Toptraders : Form
    {
        public Toptraders()
        {
            InitializeComponent();
        }

        private void groupControl1_Paint(object sender, PaintEventArgs e)
        {

        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnView_Click(object sender, EventArgs e)
        {
            if(txtClientCount.Text == "")
            {
                MessageBox.Show("Specify the desired number of clients!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("TopTradersCommission", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@records", Convert.ToInt32(txtClientCount.Text));
                    SqlParameter p2 = new SqlParameter("@nmi", "");
                    SqlParameter p3 = new SqlParameter("@startdate", dtStart.DateTime.Date);
                    SqlParameter p4 = new SqlParameter("@enddate", dtEnd.DateTime.Date);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                    cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.ExecuteNonQuery();

                    if(rdoCommission.Checked == true)
                    {
                        ViewReports.TopTradersCommission topComm = new ViewReports.TopTradersCommission();
                        topComm.Parameters["startdate"].Value = dtStart.Text;
                        topComm.Parameters["enddate"].Value = dtEnd.Text;
                        topComm.Parameters["user"].Value = ClassGenLib.username;
                        topComm.Parameters["top"].Value = txtClientCount.Text;

                        ((SqlDataSource)topComm.DataSource).ConfigureDataConnection += ViewDeals_ConfigureDataConnection;
                        ReportPrintTool tool = new ReportPrintTool(topComm);
                        tool.ShowPreview();
                    }

                    if (rdoVolume.Checked == true)
                    {
                        ViewReports.TopTradersVolume topVol = new ViewReports.TopTradersVolume();
                        topVol.Parameters["startdate"].Value = dtStart.Text;
                        topVol.Parameters["enddate"].Value = dtEnd.Text;
                        topVol.Parameters["user"].Value = ClassGenLib.username;
                        topVol.Parameters["top"].Value = txtClientCount.Text;

                        ((SqlDataSource)topVol.DataSource).ConfigureDataConnection += ViewDeals_ConfigureDataConnection;
                        ReportPrintTool tool = new ReportPrintTool(topVol);
                        tool.ShowPreview();
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void ViewDeals_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
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

        private void labelControl3_Click(object sender, EventArgs e)
        {

        }
    }
}
