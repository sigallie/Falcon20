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

using DBUtils;
using Clients;
using GenLib;

namespace Transactions
{
    public partial class NewTransaction : Form
    {
        public NewTransaction()
        {
            InitializeComponent();
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
                    MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
        }

        private void xtraTabPage2_Paint(object sender, PaintEventArgs e)
        {

        }

        private void btnClose1_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnNext_Click(object sender, EventArgs e)
        {
            if(txtClient.Text == "")
            {
                MessageBox.Show("Please select client first!", "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            if (cmbTransType.Text == "")
            {
                MessageBox.Show("Please select transaction type first!", "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            if (cmbCashAccount.Text == "" && !cmbTransType.Text.Contains("JOURNAL"))
            {
                if (cmbTransType.Text.Contains("RECEIPT OF FUNDS") || cmbTransType.Text.Contains("PAYMENT TO CLIENT"))
                {
                    MessageBox.Show("Please select bank first!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    return;
                }
            }

            if (dtDate.Text == "")
            {
                MessageBox.Show("Please select transaction date first!", "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            txtPayAmount.Focus();
            for(int i = 0; i < xtraTabControl1.TabPages.Count; i++)
            {
                xtraTabControl1.TabPages[i].PageVisible = false;
            }
            if (cmbTransType.Text == "PAYMENT TO CLIENT - PAY")
            {
                tbDetails.PageVisible = true;
                txtPayAmount.Focus();
            }
            else if (cmbTransType.Text == "RECEIPT OF FUNDS - REC")
            {
                tbReceipt.PageVisible = true;
                txtReceiptAmount.Focus();
            }
            else if(cmbTransType.Text.Contains("CNL"))
            {
                //list all transactions posted on the client's account of the selected original transcode type
                string fullCode = cmbTransType.Text.Substring(cmbTransType.Text.IndexOf("-") + 2);
                string ogCode = fullCode.Substring(0, fullCode.Length - 3);
                //MessageBox.Show(fullCode +" "+ogCode);

                using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        string strSQL = "select transid, clientno, postdate, transcode, transdate, [description], amount, [login] ";
                        strSQL += "from transactions ";
                        strSQL += "where clientno = '"+ClassGenLib.selectedClient+"' ";
                        strSQL += "and transcode = '"+ogCode.Trim()+"' ";
                        strSQL += "order by transdate, transid desc";

                        SqlCommand cmd = new SqlCommand(strSQL, conn);

                        using(SqlDataAdapter da = new SqlDataAdapter(cmd))
                        {
                            DataTable dt = new DataTable();
                            da.Fill(dt);

                            grdReversal.DataSource = dt;
                        }

                        tbReversal.PageVisible = true;
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                    finally
                    {
                        if (conn != null)
                            conn.Close();
                    }
                }
            }
            else
            {
                tbOther.PageVisible = true;
                txtOtherAmount.Focus();
            }

            
        }

        private void btnBack_Click(object sender, EventArgs e)
        {
            for (int i = 0; i < xtraTabControl1.TabPages.Count; i++)
            {
                xtraTabControl1.TabPages[i].PageVisible = false;
            }
            tbTransaction.PageVisible = true;
        }

        private void NewTransaction_Load(object sender, EventArgs e)
        {
            //load the user-initiated transaction types
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select [description] +' - '+ transtype from transtypes where auto = 0 and active = 1 order by [description]", conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    while(rd.Read())
                    {
                        cmbTransType.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();

                    cmd.CommandText = "select code from cashbooks where active = 'ACTIVE' order by code";

                    rd = cmd.ExecuteReader();
                    while(rd.Read())
                    {
                        cmbCashAccount.Properties.Items.Add(rd[0].ToString());
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

        private void btnSave_Click(object sender, EventArgs e)
        {
            //post the requisition
            if(txtClient.Text == "" || cmbTransType.Text == "" || txtPayAmount.Text == "")
            {
                MessageBox.Show("Insufficient details supplied!", "Falcon 2", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    int CashBookID = 0;


                    conn.Open();

                    SqlCommand cmdCash = new SqlCommand("select dbo.fnGetCashBookID('"+cmbCashAccount.Text+"')", conn);
                    CashBookID = Convert.ToInt32(cmdCash.ExecuteScalar());

                    double amount = Convert.ToDouble(txtPayAmount.Text.Replace(",", ""));

                    SqlCommand cmd = new SqlCommand("RequisitionPayRec", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@user", ClassGenLib.username);
                    SqlParameter p2 = new SqlParameter("@clientno", ClassGenLib.selectedClient);
                    SqlParameter p3 = new SqlParameter("@transcode", cmbTransType.Text.Substring(0, cmbTransType.Text.IndexOf("-")).Trim());
                    SqlParameter p4 = new SqlParameter("@transdate", dtDate.DateTime);
                    SqlParameter p5 = new SqlParameter("@description", cmbTransType.Text);
                    SqlParameter p6 = new SqlParameter("@amount", amount);
                    SqlParameter p7 = new SqlParameter("@cash", true);
                    SqlParameter p8 = new SqlParameter("@CashBookID", CashBookID);
                    SqlParameter p9 = new SqlParameter("@ChqRqID", 1);
                    SqlParameter p10 = new SqlParameter("@ExCurrency", "ZWL");
                    SqlParameter p11 = new SqlParameter("@ExRate", 1);
                    SqlParameter p12 = new SqlParameter("@ExAmount", 1);
                    SqlParameter p13 = new SqlParameter("@Method", "DIRECT");
                    SqlParameter p14 = new SqlParameter("@nonstatement", chkNonstatement.Checked);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                    cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.Parameters.Add(p5); cmd.Parameters.Add(p6);
                    cmd.Parameters.Add(p7); cmd.Parameters.Add(p8);
                    cmd.Parameters.Add(p9); cmd.Parameters.Add(p10);
                    cmd.Parameters.Add(p11); cmd.Parameters.Add(p12);
                    cmd.Parameters.Add(p13); cmd.Parameters.Add(p14);
                    cmd.ExecuteNonQuery();

                    SqlCommand cmd1 = new SqlCommand("select approvepayments from businessrules", conn);
                    bool approvePay = Convert.ToBoolean(cmd1.ExecuteScalar());

                    if(approvePay == false) //no payments approval required so post payment to client account
                    {
                        cmd1.CommandText = "select max(reqid) from requisitions where [login] = '" + ClassGenLib.username + "'";
                        long reqid = Convert.ToInt64(cmd1.ExecuteScalar().ToString());

                        SqlCommand cmdApprove = new SqlCommand("spApproveTransaction", conn);
                        cmdApprove.CommandType = CommandType.StoredProcedure;


                        SqlParameter pA1 = new SqlParameter("@reqid", reqid);
                        SqlParameter pA2 = new SqlParameter("@user", ClassGenLib.username);

                        cmdApprove.Parameters.Add(pA1);
                        cmdApprove.Parameters.Add(pA2);
                        cmdApprove.ExecuteNonQuery();
                         
                    }

                    MessageBox.Show("Transaction posted successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    txtClient.Text = ""; txtPayAmount.Text = ""; txtPayBalance.Text = "";
                    txtReceiptAmount.Text = "";
                    txtReceiptBalance.Text = "";
                    cmbCashAccount.Text = ""; cmbTransType.Text = "";
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

        private void tbTransaction_Paint(object sender, PaintEventArgs e)
        {

        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnReceiptClose_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnReceiptSave_Click(object sender, EventArgs e)
        {
            //post the requisition
            if (txtClient.Text == "" || cmbTransType.Text == "" || txtReceiptAmount.Text == "")
            {
                MessageBox.Show("Insufficient details supplied!", "Falcon 2", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("RequisitionPayRec", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    ////SqlParameter p1 = new SqlParameter("@user", ClassGenLib.username);
                    ////SqlParameter p2 = new SqlParameter("@clientno", ClassGenLib.selectedClient);
                    ////SqlParameter p3 = new SqlParameter("@transcode", cmbTransType.Text.Substring(cmbTransType.Text.IndexOf("-") + 1).Trim());
                    ////SqlParameter p4 = new SqlParameter("@transdate", dtDate.Text);
                    ////SqlParameter p5 = new SqlParameter("@description", cmbTransType.Text.Substring(cmbTransType.Text.IndexOf("-") + 1).Trim());
                    ////SqlParameter p6 = new SqlParameter("@amount", txtReceiptAmount.Text);
                    ////SqlParameter p7 = new SqlParameter("@cash", true);
                    ////SqlParameter p8 = new SqlParameter("@CashBookID", 1);
                    ////SqlParameter p9 = new SqlParameter("@ChqRqID", 1);
                    ////SqlParameter p10 = new SqlParameter("@ExCurrency", "ZWL");
                    ////SqlParameter p11 = new SqlParameter("@ExRate", 1);
                    ////SqlParameter p12 = new SqlParameter("@ExAmount", 1);
                    ////SqlParameter p13 = new SqlParameter("@Method", "DIRECT");

                    SqlCommand cmdCashBook = new SqlCommand("select isnull(id, 0) from cashbooks where code= '"+cmbCashAccount.Text+"'", conn);
                    int cashID = Convert.ToInt32(cmdCashBook.ExecuteScalar());

                    double amount = Convert.ToDouble(txtReceiptAmount.Text.Replace(",", ""));

                    SqlParameter p1 = new SqlParameter("@user", ClassGenLib.username);
                    SqlParameter p2 = new SqlParameter("@clientno", ClassGenLib.selectedClient);
                    SqlParameter p3 = new SqlParameter("@transcode", cmbTransType.Text.Substring(0, cmbTransType.Text.IndexOf("-")).Trim());
                    SqlParameter p4 = new SqlParameter("@transdate", dtDate.DateTime.Date);
                    SqlParameter p5 = new SqlParameter("@description", cmbTransType.Text);
                    SqlParameter p6 = new SqlParameter("@amount", amount);
                    SqlParameter p7 = new SqlParameter("@cash", true);
                    SqlParameter p8 = new SqlParameter("@CashBookID", cashID);
                    SqlParameter p9 = new SqlParameter("@ChqRqID", 1);
                    SqlParameter p10 = new SqlParameter("@ExCurrency", "ZWL");
                    SqlParameter p11 = new SqlParameter("@ExRate", 1);
                    SqlParameter p12 = new SqlParameter("@ExAmount", 1);
                    SqlParameter p13 = new SqlParameter("@Method", "DIRECT");
                    SqlParameter p14 = new SqlParameter("@nonstatement", chkNonstatement.Checked);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                    cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.Parameters.Add(p5); cmd.Parameters.Add(p6);
                    cmd.Parameters.Add(p7); cmd.Parameters.Add(p8);
                    cmd.Parameters.Add(p9); cmd.Parameters.Add(p10);
                    cmd.Parameters.Add(p11); cmd.Parameters.Add(p12);
                    cmd.Parameters.Add(p13); cmd.Parameters.Add(p14);
                    cmd.ExecuteNonQuery();

                    SqlCommand cmd1 = new SqlCommand("select approvereceipts from businessrules", conn);
                    bool approveReceipt = Convert.ToBoolean(cmd1.ExecuteScalar());

                    if (approveReceipt == false) //no payments approval required so post payment to client account
                    {
                        cmd1.CommandText = "select max(reqid) from requisitions where [login] = '" + ClassGenLib.username + "'";
                        long reqid = Convert.ToInt64(cmd1.ExecuteScalar().ToString());

                        SqlCommand cmdApprove = new SqlCommand("spApproveTransaction", conn);
                        cmdApprove.CommandType = CommandType.StoredProcedure;

                        SqlParameter pA1 = new SqlParameter("@reqid", reqid);
                        SqlParameter pA2 = new SqlParameter("@user", ClassGenLib.username);

                        cmdApprove.Parameters.Add(pA1);
                        cmdApprove.Parameters.Add(pA2);
                        cmdApprove.ExecuteNonQuery();

                    }

                    MessageBox.Show("Transaction posted successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);

                    txtReceiptAmount.Text = "";
                    txtReceiptBalance.Text = "";
                    dtDate.Text = "";
                    cmbCashAccount.Text = "";
                    cmbTransType.Text = "";
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

        private void cmbTransType_SelectedValueChanged(object sender, EventArgs e)
        {
            if (cmbTransType.Text.Contains("RECEIPT OF FUNDS"))
            {
                cmbCashAccount.Enabled = true;
                chkPrint.Text = "Print Receipt";
                chkPrint.Visible = true;
            }
            else if((cmbTransType.Text.Contains("PAYMENT TO CLIENT")))
            {
                cmbCashAccount.Enabled = true;
                chkPrint.Text = "Print Requisition";
                chkPrint.Visible = true;
            }
            else
            {
                cmbCashAccount.Enabled = false;
                chkPrint.Visible = false;
                chkPrint.Checked = false;
            }
            cmbCashAccount.Text = "";
        }

        private void btnOtherClose_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnOtherBack_Click(object sender, EventArgs e)
        {
            for (int i = 0; i < xtraTabControl1.TabPages.Count; i++)
            {
                xtraTabControl1.TabPages[i].PageVisible = false;
            }
            tbTransaction.PageVisible = true;
        }

        private void btnOtherSave_Click(object sender, EventArgs e)
        {
            if(txtOtherAmount.Text == "" || txtOtherComment.Text == "")
            {
                MessageBox.Show("Please specify all details!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    double amount = Convert.ToDouble(txtOtherAmount.Text.Replace(",", ""));

                    SqlCommand cmd = new SqlCommand("RequisitionPayRec", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@user", ClassGenLib.username);
                    SqlParameter p2 = new SqlParameter("@clientno", ClassGenLib.selectedClient);
                    SqlParameter p3 = new SqlParameter("@transcode", cmbTransType.Text.Substring(cmbTransType.Text.IndexOf("-") + 1).Trim());
                    SqlParameter p4 = new SqlParameter("@transdate", dtDate.DateTime);
                    SqlParameter p5 = new SqlParameter("@description", cmbTransType.Text);
                    SqlParameter p6 = new SqlParameter("@amount", amount);
                    SqlParameter p7 = new SqlParameter("@cash", true);
                    SqlParameter p8 = new SqlParameter("@CashBookID", 0);
                    SqlParameter p9 = new SqlParameter("@ChqRqID", 1);
                    SqlParameter p10 = new SqlParameter("@ExCurrency", "ZWL");
                    SqlParameter p11 = new SqlParameter("@ExRate", 1);
                    SqlParameter p12 = new SqlParameter("@ExAmount", 1);
                    SqlParameter p13 = new SqlParameter("@Method", "DIRECT");
                    SqlParameter p14 = new SqlParameter("@nonstatement", chkNonstatement.Checked);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                    cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.Parameters.Add(p5); cmd.Parameters.Add(p6);
                    cmd.Parameters.Add(p7); cmd.Parameters.Add(p8);
                    cmd.Parameters.Add(p9); cmd.Parameters.Add(p10);
                    cmd.Parameters.Add(p11); cmd.Parameters.Add(p12);
                    cmd.Parameters.Add(p13); cmd.Parameters.Add(p14);
                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Transaction posted successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);

                    txtOtherAmount.Text = ""; txtOtherComment.Text = "";

                    dtDate.Text = "";
                    cmbTransType.Text = "";
                    txtClient.Text = "";
                    tbOther.PageVisible = false;
                    tbTransaction.PageVisible = true;
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
        }

        private void tbReversal_Paint(object sender, PaintEventArgs e)
        {

        }

        private void cmbTransType_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Enter)
            {
                if (cmbTransType.Text.Contains("RECEIPT OF FUNDS") || cmbTransType.Text.Contains("PAYMENT TO CLIENT"))
                {
                    cmbCashAccount.Enabled = true;
                    cmbCashAccount.Focus();
                }
                else
                {
                    cmbCashAccount.Enabled = false;
                    dtDate.Focus();
                }
            }
        }

        private void btnReversalBack_Click(object sender, EventArgs e)
        {
            for (int i = 0; i < xtraTabControl1.TabPages.Count; i++)
            {
                xtraTabControl1.TabPages[i].PageVisible = false;
            }
            tbTransaction.PageVisible = true;
        }

        private void btnReversalSave_Click(object sender, EventArgs e)
        {
            //post the reversal transaction. It does not require approval
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    string strSQL = "";
                    SqlCommand cmd = new SqlCommand("PayRec", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@user", ClassGenLib.username);
                    SqlParameter p2 = new SqlParameter("@clientno", ClassGenLib.selectedClient);
                    SqlParameter p3 = new SqlParameter("@transcode", SqlDbType.VarChar);
                    SqlParameter p4 = new SqlParameter("@transdate", SqlDbType.DateTime);
                    SqlParameter p5 = new SqlParameter("@description", SqlDbType.VarChar);
                    SqlParameter p6 = new SqlParameter("@amount", SqlDbType.Decimal);
                    SqlParameter p7 = new SqlParameter("@transid", SqlDbType.BigInt);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                    cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.Parameters.Add(p5); cmd.Parameters.Add(p6);
                    cmd.Parameters.Add(p7); 

                    for(int i = 0; i < vwReversal.RowCount; i++)
                    {
                        if(vwReversal.IsRowSelected(i))
                        {
                            p3.Value = vwReversal.GetRowCellValue(i, "transcode").ToString() + "CNL";
                            p4.Value = vwReversal.GetRowCellValue(i, "transdate").ToString();
                            p5.Value = vwReversal.GetRowCellValue(i, "description").ToString();
                            p6.Value = vwReversal.GetRowCellValue(i, "amount").ToString();
                            p7.Value = vwReversal.GetRowCellValue(i, "transid").ToString();

                            cmd.ExecuteNonQuery();
                            break;
                        }
                    }

                  
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
        }

        private void cmbCashAccount_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Enter)
            {
                dtDate.Focus();
            }
        }

        private void dtDate_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Enter)
            {
                mmoDescription.Focus();
            }
        }

        private void mmoDescription_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Enter)
            {
                btnNext.Focus();
            }
        }
    }
}
