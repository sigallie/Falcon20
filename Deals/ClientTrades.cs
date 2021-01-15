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

using DBUtils;
using GenLib;
using Deals;
using ViewReports;
using CrystalRpts;

using DevExpress.Data;
using DevExpress.DataAccess;
using DevExpress.DataAccess.Sql;
using DevExpress.DataAccess.ConnectionParameters;

namespace Clients
{
    public partial class ClientTrades : Form
    {
        public ClientTrades()
        {
            InitializeComponent();
        }

        private void txtClient_ButtonClick(object sender, DevExpress.XtraEditors.Controls.ButtonPressedEventArgs e)
        {
            ClientListing lst = new ClientListing();
            lst.ShowDialog();

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    //string strSQL = "select distinct dealtype, dealdate, dealno, asset, qty, price, consideration, dealvalue, grosscommission, stampduty, vat, capitalgains, investorprotection, zselevy, commissionerlevy, csdlevy from vwDealAllocations where clientno = '" + ClassGenLib.selectedClient + "' order by dealdate";
                    string strSQL = "select * from vwDealAllocations where clientno = '" + ClassGenLib.selectedClient + "' order by dealdate, id";

                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    using(SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdTrades.DataSource = dt;                        
                    }

                    cmd.CommandText = "select * from cashbooktrans where clientno = '" + ClassGenLib.selectedClient + "' order by transdate desc";
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        
                        da.Fill(dt);

                        grdTransactions.DataSource = dt;
                    }

                    SqlCommand cmdPort = new SqlCommand("spGetClientPortfolio", conn);
                    cmdPort.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@clientno", ClassGenLib.selectedClient);
                    SqlParameter p2 = new SqlParameter("@user", ClassGenLib.username);
                    cmdPort.Parameters.Add(p1); cmdPort.Parameters.Add(p2);
                    cmdPort.ExecuteNonQuery();

                    strSQL = "select x.asset, x.bought, x.sold, (x.bought-x.sold) as net, a.assetname ";
                    strSQL += " from tblClientPortfolio x inner join assets a on x.asset = a.assetcode where x.clientno = '" + ClassGenLib.selectedClient + "'";

                    using (SqlDataAdapter da = new SqlDataAdapter(strSQL, conn))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdPortfolio.DataSource = dt;
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

        private void vwTrades_KeyUp(object sender, KeyEventArgs e)
        {
            string reportName = "";
            string dealno = "";

            if (e.KeyCode == Keys.F3)
            {
                //print the deal not for the selected deal(s)
                for (int i = 0; i < vwTrades.RowCount; i++)
                {
                    if (vwTrades.IsRowSelected(i))
                    {
                        dealno = vwTrades.GetRowCellValue(i, "dealno").ToString();
                        if (dealno.Substring(0, 1) == "B")
                        {
                            ViewReports.BNOTE bnote = new ViewReports.BNOTE();
                            bnote.Parameters["dealno"].Value = dealno;

                            ((SqlDataSource)bnote.DataSource).ConfigureDataConnection += ClientTrades_ConfigureDataConnection;
                            ReportPrintTool tool = new ReportPrintTool(bnote);
                            tool.ShowPreview();
                        }
                        else if (dealno.Substring(0, 1) == "S")
                        {
                            ViewReports.SNOTE snote = new ViewReports.SNOTE();
                            snote.Parameters["dealno"].Value = dealno;


                            ((SqlDataSource)snote.DataSource).ConfigureDataConnection += ClientTrades_ConfigureDataConnection;
                            ReportPrintTool tool = new ReportPrintTool(snote);
                            tool.ShowPreview();

                        }
                        break;
                    }
                }
            }
                if (e.KeyCode == Keys.F10)
                {
                    NewDeal ndeal = new NewDeal();
                    ndeal.ShowDialog();
                }
        }

        private void ClientTrades_Load(object sender, EventArgs e)
        {

        }

        private void grdTrades_Click(object sender, EventArgs e)
        {

        }

        private void txtClient_EditValueChanged(object sender, EventArgs e)
        {

        }

        private void ClientTrades_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
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
