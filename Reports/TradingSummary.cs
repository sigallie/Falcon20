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
using DevExpress.DataAccess.Sql;
using DevExpress.DataAccess.ConnectionParameters;

using Excel = Microsoft.Office.Interop.Excel;


using DBUtils;
using GenLib;



namespace Reports
{
    public partial class TradingSummary : Form
    {
        string serverIP = "";
        public TradingSummary()
        {
            InitializeComponent();
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            //Close();
            //export to excel format

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select category, client, dealno, asset, qty, price, format(consideration, 'n2'), format(grosscommission, 'n2'), format(stampduty, 'n2'), format(vat, 'n2'), format(capitalgains, 'n2'), format(investorprotection, 'n2'), format(zselevy, 'n2'), format(commissionerlevy, 'n2'), format(csdlevy, 'n2') from vwDaybookAllocations where dealdate = '" + DateTime.Now.ToString() + "'", conn);
                    var da = new SqlDataAdapter(cmd);
                    var dt = new DataTable();
                    da.Fill(dt);

                    Excel.Application excelApp = new Excel.Application();
                    Excel.Workbook xBook = excelApp.Workbooks.Open(Filename: Environment.CurrentDirectory + @"\FalconReports\DayBook.xlt", Editable: true); //open excel template in edit mode
                    Excel.Worksheet ws = (Excel.Worksheet)xBook.Sheets["Sheet1"];

                    object[,] arrDayBook = new object[dt.Rows.Count + 4, dt.Columns.Count];

                    arrDayBook[3, 0] = "Category";
                    arrDayBook[3, 1] = "Client";
                    arrDayBook[3, 2] = "Deal No.";
                    arrDayBook[3, 3] = "Counter";
                    arrDayBook[3, 4] = "Qty";
                    arrDayBook[3, 5] = "Price";
                    arrDayBook[3, 6] = "Consideration";
                    arrDayBook[3, 7] = "Commission";
                    arrDayBook[3, 8] = "Stamp Duty";
                    arrDayBook[3, 9] = "VAT";
                    arrDayBook[3, 10] = "Capital Gains";
                    arrDayBook[3, 11] = "Investor Protection";
                    arrDayBook[3, 12] = "ZSE Levy";
                    arrDayBook[3, 13] = "Commissioner's Levy";
                    arrDayBook[3, 14] = "CSD Levy";
                    int rows = 0;
                    for (int r = 0; r < dt.Rows.Count; r++)
                    {
                        DataRow dRow = dt.Rows[r];
                        for (int c = 0; c < dt.Columns.Count; c++)
                        {
                            arrDayBook[r + 4, c] = dRow[c];
                        }
                        rows = r;
                    }


                    arrDayBook[dt.Rows.Count, 6] = "20";
                    arrDayBook[rows + 4, 7] = "Commission";
                    arrDayBook[rows + 4, 8] = "Stamp Duty";
                    arrDayBook[rows + 4, 9] = "VAT";
                    arrDayBook[rows + 4, 10] = "Capital Gains";
                    arrDayBook[rows + 4, 11] = "Investor Protection";
                    arrDayBook[rows + 4, 12] = "ZSE Levy";
                    arrDayBook[rows + 4, 13] = "Commissioner's Levy";
                    arrDayBook[rows + 4, 14] = "CSD Levy";

                    Excel.Range c1 = (Excel.Range)ws.Cells[1, 1];
                    Excel.Range c2 = (Excel.Range)ws.Cells[dt.Rows.Count + 2, dt.Columns.Count];
                    Excel.Range range = ws.get_Range(c1, c2);
                    range.Value = arrDayBook;

                    SaveFileDialog save = new SaveFileDialog();
                    save.InitialDirectory = @"C:\";
                    save.DefaultExt = "xls";

                    if (save.ShowDialog() == DialogResult.OK)
                    {
                        xBook.SaveAs(save.FileName);
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason - " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                }
            }
        }

        private void btnView_Click(object sender, EventArgs e)
        {
            if (dtStart.Text == "" || dtEnd.Text == "")
            {
                MessageBox.Show("Specify the date range", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmdServer = new SqlCommand("select dbserverip from tblsystemparams", conn);
                    serverIP = cmdServer.ExecuteScalar().ToString();

                    SqlCommand cmd = new SqlCommand("spSummaryTrading", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@startdate", dtStart.DateTime);
                    SqlParameter p2 = new SqlParameter("@enddate", dtEnd.DateTime);
                    SqlParameter p3 = new SqlParameter("@user", ClassGenLib.username);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3);
                    cmd.ExecuteNonQuery();

                    ViewReports.TradingSummary sumT = new ViewReports.TradingSummary();
                    sumT.Parameters["sdate"].Value = dtStart.DateTime;
                    sumT.Parameters["edate"].Value = dtEnd.DateTime;
                    sumT.Parameters["user"].Value = ClassGenLib.username;

                    ((SqlDataSource)sumT.DataSource).ConfigureDataConnection += TradingSummary_ConfigureDataConnection;
                    //((SqlDataSource)sumT.DataSource).ConfigureDataConnection += ClassDBUtils.ConfigureDataConnection();

                    ReportPrintTool tool = new ReportPrintTool(sumT);
                    tool.ShowPreview();
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Failed to onnect to database! " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                }
            }
        }

        private void TradingSummary_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
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