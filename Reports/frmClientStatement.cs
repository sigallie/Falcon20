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


using Clients;
using DBUtils;
using GenLib;
using ViewReports;
using CrystalRpts;

namespace Reports
{
    public partial class frmClientStatement : Form
    {
        public frmClientStatement()
        {
            InitializeComponent();
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void txtClient_ButtonClick(object sender, DevExpress.XtraEditors.Controls.ButtonPressedEventArgs e)
        {
            ClientListing lstClients = new ClientListing();
            lstClients.ShowDialog();

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select clientname from vwClientListing where clientno = '" + ClassGenLib.selectedClient + "'", conn);
                    string strSQL = cmd.CommandText;
                    txtClient.Text = cmd.ExecuteScalar().ToString();
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

        private void btnView_Click(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    //SqlCommand cmd = new SqlCommand("spClientStatement", conn);
                    SqlCommand cmd = new SqlCommand("PopulateStatementsReport", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@ClientNo", ClassGenLib.selectedClient);
                    SqlParameter p2 = new SqlParameter("@StartDate", dtStart.DateTime.Date);
                    SqlParameter p3 = new SqlParameter("@EndDate", dtEnd.DateTime.Date);
                    SqlParameter p4 = new SqlParameter("@User", ClassGenLib.username);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                    cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.ExecuteNonQuery();

                    //ViewReports.ClientStatement stmt = new ViewReports.ClientStatement();
                    ViewReports.StatementReport stmt = new ViewReports.StatementReport();
                    stmt.Parameters["username"].Value = ClassGenLib.username;
                    stmt.Parameters["clientno"].Value = ClassGenLib.selectedClient;
                    stmt.Parameters["startdate"].Value = dtStart.Text;
                    stmt.Parameters["enddate"].Value = dtEnd.Text;

                    ((SqlDataSource)stmt.DataSource).ConfigureDataConnection += frmClientStatements_ConfigureDataConnection;

                    ReportPrintTool tool = new ReportPrintTool(stmt);
                    tool.ShowPreview();

                    //CrystalForm rpts = new CrystalForm("STATEMENT", "", ClassGenLib.selectedClient, dtStart.DateTime, dtEnd.DateTime);
                    //rpts.ShowDialog();
                }
                catch(Exception ex)
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

        private void frmClientStatements_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
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

        private void frmClientStatement_Load(object sender, EventArgs e)
        {

        }
    }
}
