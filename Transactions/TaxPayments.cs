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
using GenLib;

namespace Transactions
{
    public partial class TaxPayments : Form
    {
        string CashBook;
        string TransCode, Description;
        string ClientNo;
        public string CurrentUser = ClassGenLib.username;
        public TaxPayments()
        {
            InitializeComponent();
        }

        private void grpTax_Paint(object sender, PaintEventArgs e)
        {

        }

        private void TaxPayments_Load(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    //SqlCommand cmd = new SqlCommand("select ledgername from LedgerAccount order by ledgername", conn);
                    SqlCommand cmd = new SqlCommand("select [description] from transtypes where auto = 0 and active = 1 and (transtype like '%DUE')", conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    while(rd.Read())
                    {
                        cmbTransType.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();

                    cmd.CommandText = "select code from cashbooks order by code";
                    rd = cmd.ExecuteReader();
                    while(rd.Read())
                    {
                        cmbTransAccount.Properties.Items.Add(rd[0].ToString());
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

        private void cmbTransType_SelectedValueChanged(object sender, EventArgs e)
        {
            grpTax.Text = "You are about to pay " + cmbTransType.Text;
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    Double transAmount = 0;
                    Double cashAmount = 0;

                    //SqlCommand cmd = new SqlCommand("select ledgercode from LedgerAccount where ledgername = '"+cmbTransType.Text+"'", conn);
                    SqlCommand cmd = new SqlCommand("select ledgercode from Transtypes where [description] = '" + cmbTransType.Text + "'", conn);
                    txtClientNo.Text = cmd.ExecuteScalar().ToString();

                    //cmd.CommandText = "select ledgerabbrev from LedgerAccount where ledgername = '" + cmbTransType.Text + "'";
                    //TransCode = cmd.ExecuteScalar().ToString();

                    cmd.CommandText = "select isnull(sum(amount), 0) from transactions where clientno = '" + txtClientNo.Text + "' and transdate >= '20190401'";
                    transAmount = Convert.ToDouble(cmd.ExecuteScalar()); // "#,###,##0.00");
                    
                    cmd.CommandText = "select isnull(-sum(amount), 0) from cashbooktrans where clientno = '" + txtClientNo.Text + "' and transdate >= '20190401'";
                    cashAmount = Convert.ToDouble(cmd.ExecuteScalar()); // "#,###,##0.00");

                    txtAmountOwing.Text = (transAmount + cashAmount).ToString();
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

        public static void ClearForm(System.Windows.Forms.Control parent)
        {
            foreach (System.Windows.Forms.Control ctrControl in parent.Controls)
            {
                //Loop through all controls 
                if (object.ReferenceEquals(ctrControl.GetType(), typeof(System.Windows.Forms.TextBox)))
                {
                    //Check to see if it's a textbox 
                    ((System.Windows.Forms.TextBox)ctrControl).Text = string.Empty;
                    //If it is then set the text to String.Empty (empty textbox) 
                }
                else if (object.ReferenceEquals(ctrControl.GetType(), typeof(DevExpress.XtraEditors.TextEdit)))
                {
                    //Check to see if it's a textbox 
                    ((DevExpress.XtraEditors.TextEdit)ctrControl).Text = string.Empty;
                    //If it is then set the text to String.Empty (empty textbox) 
                }
                else if (object.ReferenceEquals(ctrControl.GetType(), typeof(System.Windows.Forms.RichTextBox)))
                {
                    //If its a RichTextBox clear the text
                    ((System.Windows.Forms.RichTextBox)ctrControl).Text = string.Empty;
                }
                else if (object.ReferenceEquals(ctrControl.GetType(), typeof(System.Windows.Forms.ComboBox)))
                {
                    //Next check if it's a dropdown list 
                    ((System.Windows.Forms.ComboBox)ctrControl).SelectedIndex = -1;
                    //If it is then set its SelectedIndex to 0 
                }
                else if (object.ReferenceEquals(ctrControl.GetType(), typeof(System.Windows.Forms.CheckBox)))
                {
                    //Next uncheck all checkboxes
                    ((System.Windows.Forms.CheckBox)ctrControl).Checked = false;
                }
                else if (object.ReferenceEquals(ctrControl.GetType(), typeof(System.Windows.Forms.RadioButton)))
                {
                    //Unselect all RadioButtons
                    ((System.Windows.Forms.RadioButton)ctrControl).Checked = false;
                }
                if (ctrControl.Controls.Count > 0)
                {
                    //Call itself to get all other controls in other containers 
                    ClearForm(ctrControl);
                }

            }
        }

        private void btnProcess_Click(object sender, EventArgs e)
        {
            try
            {
                DateTime TransDate;
                string Currency = "USD";
                double ExRate = 0;
                double ExAmount = 0;
                string DTime = "";


                if (cmbTransType.Text == "")
                {
                    MessageBox.Show("Please, select the tax account", "Tax Account Error", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    txtClientNo.Focus();
                    return;
                }

                if (double.Parse(txtAmount.Text) <= 0)
                {
                    MessageBox.Show("Amount must be greater than zero", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    txtAmount.Focus();
                    return;
                }

                if (dtDate.Text == "")
                {
                    MessageBox.Show("Transaction date cannot be blank", "Transaction Date Error", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    dtDate.Focus();
                    return;
                }


                if (Convert.ToDateTime(dtDate.Text) > DateTime.Now)
                {
                    MessageBox.Show("Transaction date cannot be greater than today's date", "Transaction Date Error", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    dtDate.Focus();
                    return;
                }
                else
                    TransDate = Convert.ToDateTime(dtDate.Text);

                if (double.Parse(txtAmountOwing.Text) < double.Parse(txtAmount.Text))
                {
                    if (MessageBox.Show("You are about to overpay this account. Do you want to overpay?", "Confirm Overpayment", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.No)
                    {
                        txtAmount.Focus();
                        return;
                    }
                }

                if (double.Parse(txtAmountOwing.Text) > double.Parse(txtAmount.Text))
                {
                    if (MessageBox.Show("You are about to underpay this account. Do you want to underpay?", "Confirm Underpayment", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.No)
                    {
                        txtAmount.Focus();
                        return;
                    }
                }

                if (cmbTransAccount.Text == "")
                {
                    MessageBox.Show("Please, select the tax account", "Tax Account Error", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    cmbTransAccount.Focus();
                    return;
                }

                if (cmbMethod.Text == "")
                {
                    MessageBox.Show("Please, select method of payment", "Payment Method Error", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    cmbMethod.Focus();
                    return;
                }

                DTime = dtDate.Text + ' ' + dtpTime.Text;
                TransDate = Convert.ToDateTime(DTime);
                using (SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    string Payee, Method = "";
                    double Amount;
                    Conn.Open();
                    TransDate = Convert.ToDateTime(dtDate.Text);
                    ClientNo = txtClientNo.Text;
                    Amount = double.Parse(txtAmount.Text);
                    Payee = Description;
                    Description = txtComment.Text;
                    if (cmbMethod.Text == "CHEQUE")
                    {
                        Method = "CHEQUE";
                    }
                    else if (cmbMethod.Text == "BANK TRANSFER")
                    {
                        Method = "RTGS";
                    }

                    #region Paying all NMI Rebates

                    if (cmbTransType.Text == "NMI REBATES")
                    {


                        SqlCommand NMIcmd = new SqlCommand("AllNMIRebates @date,'" + CurrentUser + "'", Conn);
                        NMIcmd.Parameters.AddWithValue("@date", Convert.ToDateTime(dtDate.Text));
                        SqlDataReader reader = NMIcmd.ExecuteReader();
                        if (!reader.HasRows)
                        {
                            MessageBox.Show("No outstanding NMI rebates to post", "No Rebates", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                            return;
                        }

                        if (MessageBox.Show("You are about to post NMI rebates owing up to " + dtDate.Text + ". Are you sure?", "Post Rebates", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.No)
                        {
                            return;
                        }

                        while (reader.Read())
                        {
                            Amount = -double.Parse(reader["nmirebate"].ToString());
                            ClientNo = reader["clientno"].ToString();

                            SqlCommand cmd = new SqlCommand("RequisitionPayRec @User,@ClientNo,@DealNo,@TransCode,@Method,@TransDate,@Description,@Amount,@Cash,@Bank" +
                            ",@BankBranch,@ChequeNo,@Drawer,@RefNo,@CashBookID,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID", Conn);
                            cmd.Parameters.AddWithValue("@User", CurrentUser);
                            cmd.Parameters.AddWithValue("@ClientNo", ClientNo);
                            cmd.Parameters.AddWithValue("@DealNo", DBNull.Value);
                            cmd.Parameters.AddWithValue("@TransCode", TransCode+"DUE");
                            cmd.Parameters.AddWithValue("@Method", Method);
                            cmd.Parameters.AddWithValue("@TransDate", Convert.ToDateTime(dtDate.Text));
                            cmd.Parameters.AddWithValue("@Description", Description);
                            cmd.Parameters.AddWithValue("@Amount", Amount);
                            cmd.Parameters.AddWithValue("@Cash", true);
                            cmd.Parameters.AddWithValue("@Bank", DBNull.Value);
                            cmd.Parameters.AddWithValue("@BankBranch", DBNull.Value);
                            cmd.Parameters.AddWithValue("@ChequeNo", DBNull.Value);
                            cmd.Parameters.AddWithValue("@Drawer", DBNull.Value);
                            cmd.Parameters.AddWithValue("@RefNo", DBNull.Value);
                            cmd.Parameters.AddWithValue("@CashBookID", int.Parse(CashBook));
                            cmd.Parameters.AddWithValue("@ChqRqID", 0);
                            cmd.Parameters.AddWithValue("@ExCurrency", Currency);
                            cmd.Parameters.AddWithValue("@ExRate", ExRate);
                            cmd.Parameters.AddWithValue("@ExAmount", ExAmount);
                            cmd.Parameters.AddWithValue("@MatchID", 0);
                            cmd.ExecuteNonQuery();

                        }
                    }
                    #endregion
                    else
                    {
                        //Amount = -Amount;
                        
                        SqlCommand cmd = new SqlCommand("RequisitionPayRec @User,@ClientNo,@DealNo,@TransCode,@Method,@TransDate,@Description,@Amount,@Cash,@Bank" +
                        ",@BankBranch,@ChequeNo,@Drawer,@RefNo,@CashBookID,@ChqRqID,@ExCurrency,@ExRate,@ExAmount,@MatchID", Conn);
                        cmd.Parameters.AddWithValue("@User", CurrentUser);
                        cmd.Parameters.AddWithValue("@ClientNo", ClientNo);
                        cmd.Parameters.AddWithValue("@DealNo", DBNull.Value);
                        cmd.Parameters.AddWithValue("@TransCode", cmbTransType.Text);
                        cmd.Parameters.AddWithValue("@Method", Method);
                        cmd.Parameters.AddWithValue("@TransDate", Convert.ToDateTime(dtDate.Text));
                        cmd.Parameters.AddWithValue("@Description", Description);
                        cmd.Parameters.AddWithValue("@Amount", Amount);
                        cmd.Parameters.AddWithValue("@Cash", true);
                        cmd.Parameters.AddWithValue("@Bank", DBNull.Value);
                        cmd.Parameters.AddWithValue("@BankBranch", DBNull.Value);
                        cmd.Parameters.AddWithValue("@ChequeNo", DBNull.Value);
                        cmd.Parameters.AddWithValue("@Drawer", DBNull.Value);
                        cmd.Parameters.AddWithValue("@RefNo", DBNull.Value);
                        cmd.Parameters.AddWithValue("@CashBookID", int.Parse(CashBook));
                        cmd.Parameters.AddWithValue("@ChqRqID", 0);
                        cmd.Parameters.AddWithValue("@ExCurrency", Currency);
                        cmd.Parameters.AddWithValue("@ExRate", ExRate);
                        cmd.Parameters.AddWithValue("@ExAmount", ExAmount);
                        cmd.Parameters.AddWithValue("@MatchID", 0);
                        cmd.ExecuteNonQuery();
                    }
                    MessageBox.Show("Payment captured successfully", "Client Account Credited", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    Conn.Close();
                    ClearForm(this);
                    chkAmountOwing.Enabled = false;
                    chkAmountOwing.Checked = false;
                }
            }
             catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                //ScreenShot.EmailScreenShot(ex.ToString());
            }
        }

        private void cmbTransAccount_SelectedValueChanged(object sender, EventArgs e)
        {
            try
            {
                SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString);
                Conn.Open();
                using (SqlCommand cmd = new SqlCommand("select * from cashbooks where code='" + cmbTransAccount.Text + "'", Conn))
                {
                    SqlDataReader rd = cmd.ExecuteReader();
                    while (rd.Read())
                    {
                        CashBook = rd["id"].ToString();
                    }
                    rd.Close();
                }
            }

            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                //ScreenShot.EmailScreenShot(ex.ToString());
            }
        }

        private void chkAmountOwing_CheckedChanged(object sender, EventArgs e)
        {
            if(chkAmountOwing.Checked == true)
            {
                txtAmount.Text = txtAmountOwing.Text;
            }
            else
            {
                txtAmount.Text = "";
            }
        }
    }
}
