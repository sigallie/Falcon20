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
using CrystalDecisions.CrystalReports.Engine;
using DevExpress.Data.Access;
using DevExpress.DataAccess.Sql;
using DevExpress.DataAccess.ConnectionParameters;
using System.IO;
using System.Reflection;

using Excel = Microsoft.Office.Interop.Excel;

using DBUtils;
using GenLib;
using ViewReports;
using CrystalRpts;

namespace Deals
{
    public partial class ViewDeals : Form
    {
        public ViewDeals()
        {
            InitializeComponent();
        }

        private void dtDealDate_EditValueChanged(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    string year = ""; string month = ""; string day = "";
                    year = dtDealDate.DateTime.Year.ToString();
                    month = dtDealDate.DateTime.Month.ToString();
                    day = dtDealDate.DateTime.Day.ToString();

                    string date = year + "/" + month + "/" + day;
                    //string strSQL = "select * from vwDealAllocations where dealdate = '" + dtDealDate.DateTime.Date.ToString() + "' ";
                    string strSQL = "select * from vwDealAllocations where dealdate = '" + date + "' ";
                    if (rdoBroker.Checked)
                        strSQL += "and category = 'BROKER' ";
                    if (rdoNone.Checked)
                        strSQL += "and category <> 'BROKER' ";
                    strSQL += "order by asset";

                    using (SqlDataAdapter da = new SqlDataAdapter(strSQL, conn))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        grdDeals.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason - " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                }
            }
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void ViewDeals_Load(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select DBServerIP from tblSystemParams", conn);
                    ClassGenLib.ServerIP = cmd.ExecuteScalar().ToString();
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Error connecting to database! " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void btnDayBook_Click(object sender, EventArgs e)
        {
            if (dtDealDate.Text == "")
            {
                MessageBox.Show("Specify the deal date!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            if (sender == btnDayBook)
            {
                ViewReports.TradingBook book = new ViewReports.TradingBook();
                book.Parameters["dealdate"].Value = dtDealDate.Text;
                ((SqlDataSource)book.DataSource).ConfigureDataConnection += ViewDeals_ConfigureDataConnection;

                ReportPrintTool tool = new ReportPrintTool(book);
                tool.ShowPreview();
            }

            if (sender == brnExcel)
            {
                //get deals for the specified dats and populate the daybook Excel template
                using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        SqlCommand cmd = new SqlCommand("select category, client, dealno, asset, qty, price, format(consideration, 'n2'), format(grosscommission, 'n2'), format(stampduty, 'n2'), format(vat, 'n2'), format(capitalgains, 'n2'), format(investorprotection, 'n2'), format(zselevy, 'n2'), format(commissionerlevy, 'n2'), format(csdlevy, 'n2') from vwDaybookAllocations where dealdate = '" + dtDealDate.DateTime.ToString() + "'", conn);
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
                        for(int r = 0; r < dt.Rows.Count; r++)
                        {
                            DataRow dRow = dt.Rows[r];
                            for(int c = 0; c < dt.Columns.Count; c++)
                            {
                                arrDayBook[r + 4, c] = dRow[c];
                            }
                            rows = r;
                        }


                        arrDayBook[dt.Rows.Count, 6] = "20";
                        arrDayBook[rows + 4, 7] = "Commission";
                        arrDayBook[rows+4, 8] = "Stamp Duty";
                        arrDayBook[rows+4, 9] = "VAT";
                        arrDayBook[rows+4, 10] = "Capital Gains";
                        arrDayBook[rows+4, 11] = "Investor Protection";
                        arrDayBook[rows+4, 12] = "ZSE Levy";
                        arrDayBook[rows+4, 13] = "Commissioner's Levy";
                        arrDayBook[rows+4, 14] = "CSD Levy";

                        Excel.Range c1 = (Excel.Range)ws.Cells[1, 1];
                        Excel.Range c2 = (Excel.Range)ws.Cells[dt.Rows.Count + 2, dt.Columns.Count];
                        Excel.Range range = ws.get_Range(c1, c2);
                        range.Value = arrDayBook;

                        //save the Excel file
                        //DateTime date = DateTime.Now;
                        //string fileName = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) + "\\ExportedFile\\"+DateTime.Now.Year.ToString()+date.Month.ToString()+date.Day.ToString()+".xls";

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
        }

        private void printSelectedToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (rdoNone.Checked == true)
            {
                string dealno = "";
                //print the deal not for the selected deal(s)
                for (int i = 0; i < vwDeals.RowCount; i++)
                {
                    if (vwDeals.IsRowSelected(i))
                    {
                        dealno = vwDeals.GetRowCellValue(i, "dealno").ToString();
                        if (dealno.Substring(0, 1) == "B")
                        {
                            //change connection string
                            ViewReports.BNOTE bnote = new ViewReports.BNOTE();
                            bnote.Parameters["dealno"].Value = dealno;
                            ((SqlDataSource)bnote.DataSource).ConfigureDataConnection += ViewDeals_ConfigureDataConnection;

                            ReportPrintTool tool = new ReportPrintTool(bnote);
                            tool.ShowPreview();


                        }
                        else if (dealno.Substring(0, 1) == "S")
                        {
                            ViewReports.SNOTE snote = new ViewReports.SNOTE();
                            snote.Parameters["dealno"].Value = dealno;
                            ((SqlDataSource)snote.DataSource).ConfigureDataConnection += ViewDeals_ConfigureDataConnection;

                            ReportPrintTool tool = new ReportPrintTool(snote);
                            tool.ShowPreview();
                        }
                    }
                }
            }
        }

        private void printAllToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if(vwDeals.RowCount == 0)
            {
                MessageBox.Show("No deal notes to print!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            string dealno = "";

            for(int i = 0; i < vwDeals.RowCount; i++)
            {
                dealno = vwDeals.GetRowCellValue(i, "dealno").ToString();
                if (dealno.Substring(0, 1) == "B")
                {
                    ViewReports.BNOTE bnote = new ViewReports.BNOTE();
                    bnote.Parameters["dealno"].Value = dealno;
                    ((SqlDataSource)bnote.DataSource).ConfigureDataConnection += ViewDeals_ConfigureDataConnection;

                    ReportPrintTool tool = new ReportPrintTool(bnote);
                    tool.ShowPreview();
                }
                else if (dealno.Substring(0, 1) == "S")
                {
                    ViewReports.SNOTE snote = new ViewReports.SNOTE();
                    snote.Parameters["dealno"].Value = dealno;
                    ((SqlDataSource)snote.DataSource).ConfigureDataConnection += ViewDeals_ConfigureDataConnection;

                    ReportPrintTool tool = new ReportPrintTool(snote);
                    tool.ShowPreview();
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

        private void brnExcel_Click(object sender, EventArgs e)
        {

        }
    }
}

