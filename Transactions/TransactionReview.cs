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
using DevExpress.Data;
using DevExpress.DataAccess.UI;


using DBUtils;
using DevExpress.DataAccess.Sql;

namespace Transactions
{
    public partial class TransactionReview : Form
    {
        public TransactionReview()
        {
            InitializeComponent();
        }

        private void TransactionReview_Load(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    //list payments awaiting approval
                    SqlCommand cmd = new SqlCommand("select r.*, ltrim(rtrim(isnull(c.companyname, '')+' '+ isnull(c.surname, '')+' '+isnull(c.firstname, ''))) as client from requisitions r inner join clients c on r.clientno = c.clientno where r.approved = 1 and r.isreceipt = 0 and r.cancelled = 0 order by r.postdate desc, r.reqid desc", conn);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdPayments.DataSource = dt;
                    }

                    //cmd.CommandText = "select * from requisitions where approved = 0 and isreceipt = 1 and cancelled = 0 order by postdate desc, reqid desc";
                    cmd.CommandText = "select r.*, ltrim(rtrim(isnull(c.companyname, '')+' '+ isnull(c.surname, '')+' '+isnull(c.firstname, ''))) as client from requisitions r inner join clients c on r.clientno = c.clientno where r.approved = 1 and r.isreceipt = 1 and r.cancelled = 0 order by r.postdate desc, r.reqid desc";
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdReceipts.DataSource = dt;
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

        private void reprintPaymentRequisitionToolStripMenuItem_Click(object sender, EventArgs e)
        {
            int id = 0;

            for(int i = 0; i < vwPayments.RowCount; i++)
            {
                if(vwPayments.IsRowSelected(i))
                {
                    id = Convert.ToInt32(vwPayments.GetRowCellValue(i, "ReqID").ToString());
                    break;
                }
            }

            ViewReports.PeymentRequisition pay = new ViewReports.PeymentRequisition();
            pay.Parameters["id"].Value = id;

            ((SqlDataSource)pay.DataSource).ConfigureDataConnection += TransactionReview_ConfigureDataConnection;

            ReportPrintTool tool = new ReportPrintTool(pay);
            tool.ShowPreview();



            TransactionReview_Load(sender, e);
        }

        private void TransactionReview_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
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

        private void reprintReceiptToolStripMenuItem_Click(object sender, EventArgs e)
        {
            int id = 0;

            for (int i = 0; i < vwReceipts.RowCount; i++)
            {
                if (vwReceipts.IsRowSelected(i))
                {
                    id = Convert.ToInt32(vwReceipts.GetRowCellValue(i, "ReqID").ToString());
                    break;
                }
            }

            ViewReports.Receipt rcpt = new ViewReports.Receipt();
            rcpt.Parameters["id"].Value = id;

            ((SqlDataSource)rcpt.DataSource).ConfigureDataConnection += TransactionReview_ConfigureDataConnection;

            ReportPrintTool tool = new ReportPrintTool(rcpt);
            tool.ShowPreview();



            TransactionReview_Load(sender, e);
        }
    }
}
