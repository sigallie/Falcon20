using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using DevExpress.XtraReports.UI;
using DevExpress.DataAccess.ConnectionParameters;
using DevExpress.DataAccess.Sql;

using System.Data.SqlClient;
using System.Data.Sql;
using DBUtils;
using GenLib;
using ViewReports;

using Clients;
using CrystalRpts;

namespace Reports
{
    public partial class ClientBalances : Form
    {
        public ClientBalances()
        {
            InitializeComponent();
        }

        private void btnView_Click(object sender, EventArgs e)
        {
            if(dtDate.Text == "")
            {
                MessageBox.Show("Date has not be specified!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("BalancesOnly", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@asat", dtDate.DateTime.Date);
                    SqlParameter p2 = new SqlParameter("@user", ClassGenLib.username);
                    cmd.Parameters.Add(p1);
                    cmd.Parameters.Add(p2);
                    cmd.ExecuteNonQuery();

                    SqlCommand cmdBalances = new SqlCommand();
                    cmdBalances.Connection = conn;

                    Boolean clear = false;
                    string balType = "";

                    if (rdoCreditors.Checked == true)
                    {
                        cmdBalances.CommandText = "delete from tblClientBalances where balance >= 0";
                        clear = true;
                        balType = "Creditors";
                    }

                    if (rdoDebtors.Checked == true)
                    {
                        cmdBalances.CommandText = "delete from tblClientBalances where balance <= 0";
                        clear = true;
                        balType = "Debtors";
                    }

                    if (rdoAll.Checked == true)
                    {
                        cmdBalances.CommandText = "delete from tblClientBalances where balance = 0";
                        clear = true;
                        balType = "All";
                    }
                    

                    if(clear == true)
                        cmdBalances.ExecuteNonQuery();

                    ViewReports.Balances bal = new ViewReports.Balances();
                    bal.Parameters["asat"].Value = dtDate.DateTime.Date;
                    bal.Parameters["user"].Value = ClassGenLib.username;
                    bal.Parameters["type"].Value = balType;

                    ((SqlDataSource)bal.DataSource).ConfigureDataConnection += ClientBalances_ConfigureDataConnection;

                    ReportPrintTool tool = new ReportPrintTool(bal);
                    tool.ShowPreview();
                }
                catch(Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void ClientBalances_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
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

        private void ClientBalances_Load(object sender, EventArgs e)
        {

        }
    }
}
