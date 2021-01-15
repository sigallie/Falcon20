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

namespace Transactions
{
    public partial class ApproveTransaction : Form
    {
        public ApproveTransaction()
        {
            InitializeComponent();
        }

        private void ApproveTransaction_Load(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    //list payments awaiting approval
                    SqlCommand cmd = new SqlCommand("select r.*, ltrim(rtrim(isnull(c.companyname, '')+' '+ isnull(c.surname, '')+' '+isnull(c.firstname, ''))) as client from requisitions r inner join clients c on r.clientno = c.clientno where r.approved = 0 and r.isreceipt = 0 and r.cancelled = 0 order by r.postdate desc, r.reqid desc", conn);
                    using(SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdPayments.DataSource = dt;
                    }

                    //cmd.CommandText = "select * from requisitions where approved = 0 and isreceipt = 1 and cancelled = 0 order by postdate desc, reqid desc";
                    cmd.CommandText = "select r.*, ltrim(rtrim(isnull(c.companyname, '')+' '+ isnull(c.surname, '')+' '+isnull(c.firstname, ''))) as client from requisitions r inner join clients c on r.clientno = c.clientno where r.approved = 0 and r.isreceipt = 1 and r.cancelled = 0 order by r.postdate desc, r.reqid desc";
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

        private void btnReceiptsClose_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnPayClose_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnPayApprove_Click(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spApproveTransaction", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@reqid", SqlDbType.BigInt);
                    SqlParameter p2 = new SqlParameter("@user", ClassGenLib.username);

                    cmd.Parameters.Add(p1);
                    cmd.Parameters.Add(p2);

                    int rows = 0;
                    if (sender == btnPayApprove)
                        rows = vwPayments.RowCount;

                    if (sender == btnReceiptsApprove)
                        rows = vwReceipts.RowCount;

                    for(int i = 0; i < rows; i++)
                    {
                        if (sender == btnPayApprove)
                        {
                            if (vwPayments.IsRowSelected(i))
                            {
                                p1.Value = vwPayments.GetRowCellValue(i, "ReqID").ToString();
                            }
                        }

                        if (sender == btnReceiptsApprove)
                        {
                            if (vwReceipts.IsRowSelected(i))
                            {
                                p1.Value = vwReceipts.GetRowCellValue(i, "ReqID").ToString();
                            }
                        }
                    }
                    cmd.ExecuteNonQuery();

                    MessageBox.Show("Transaction(s) approved successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);

                    //print receipt
                    /*
                    
                    ViewReports.Receipt rcpt = new ViewReports.Receipt();
                    rcpt.Parameters["id"].Value = p1.Value;

                    ((SqlDataSource)rcpt.DataSource).ConfigureDataConnection += ApproveTransaction_ConfigureDataConnection;

                    ReportPrintTool tool = new ReportPrintTool(rcpt);
                    tool.ShowPreview();
                    */



                    ApproveTransaction_Load(sender, e);
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

        private void ApproveTransaction_ConfigureDataConnection(object sender, ConfigureDataConnectionEventArgs e)
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
