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

using Clients;
using DBUtils;
using GenLib;

using FalconLib;


namespace Deals
{
    public partial class NewDeal : Form
    {
        public string DealNo;
        double CommRate, VatRate, BCRate, StampDutyRate, SecLevyRate, InvestorRate, CapitalRate, ZSELevyRate, NMIRebateRate, CSDLevyRate;
        string CurrentUser = BusLib.Username;
        DateTime DealDate;
        string Buyer, Seller;
        string CSDBuy, CSDSell;

        SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString);
        public NewDeal()
        {
            InitializeComponent();
        }

        public static double CalculateCSDLevy(double Consideration, double Rate)
        {
            {
                double CSDLevyAsPercentage = Rate / 100;
                return (Consideration * CSDLevyAsPercentage);
            }
        }


        private DateTime GetSettlementDate(DateTime DealDate)
        {

            try
            {
                if(Conn.State == ConnectionState.Closed)
                Conn.Open();
                using (SqlCommand SettleCmd = new SqlCommand("select certdueby from systemparams", Conn))
                {
                    SqlDataReader SettleReader = SettleCmd.ExecuteReader();
                    while (SettleReader.Read())
                        return (DealDate.AddDays(int.Parse(SettleReader["certdueby"].ToString())));
                }
                return (DateTime.Now);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message + " Today's date is going to be used as settlement date");
                return (DateTime.Now);
            }

        }

        private void CalculateDealValue()
        {
            try
            {
                if(Conn.State == ConnectionState.Closed)
                Conn.Open();
                double Consideration, Commission, GrossCommission, BasicCharges, StampDuty = 0, Vat, SecLevy, ZSELevy, InvestorProtection, CapitalGains = 0, NMIRebate, CSDLevy;
                double Price;
                double DealValue = 0;
                double Qty = 0;
                //int DocNo;
                string DealType = "", DealNo = "";
                string ClientNo = "", Asset = "";
                string Reference = "";
                DateTime CertDueBy;

                if (ValidateInput() == false)
                {
                    return;
                }

                if (rdoSell.Checked)
                {
                    DealType = "SELL";
                    //DealNo = "S/" + GetDealNo();
                    //CapitalGains = BusLib.CalculateCapitalGains(Consideration, CapitalRate);
                }
                else if (rdoBuy.Checked)
                {
                    DealType = "BUY";
                    //DealNo = "B/" + GetDealNo();
                    // StampDuty = BusLib.CalculateStampDuty(Consideration, StampDutyRate);
                }
                else if (rdoBookover.Checked)
                {
                    DealType = "BOVER";
                    //DealNo = "B/" + GetDealNo();
                    // StampDuty = BusLib.CalculateStampDuty(Consideration, StampDutyRate);
                }

                //Reference = txtReference.Text;
                //ClientNo = txtClientNo.Text;
                Price = double.Parse(txtPrice.Text);
                Qty = double.Parse(txtQty.Text);
                CertDueBy = GetSettlementDate(DealDate); 
                Asset = cmbAsset.Text;

                Consideration = BusLib.CalculateConsideration(Qty, Price); 


                GetRates(ClientNo); 
                if (DealType == "SELL")
                {
                    CapitalGains = BusLib.CalculateCapitalGains(Consideration, CapitalRate);
                }
                else if (DealType == "BUY")
                {
                    StampDuty = BusLib.CalculateStampDuty(Consideration, StampDutyRate); 
                }

                //if (chkRemoveCommission.Checked)
                //{

                //    GrossCommission = 0;
                //    Commission = 0;
                //    NMIRebate = 0;
                //}
                //else
                //{
                //    GrossCommission = BusLib.CalculateCommission(Consideration, CommRate);
                //    Commission = (1 - NMIRebateRate) * GrossCommission;
                //    NMIRebate = NMIRebateRate * GrossCommission;
                //}
                //if (chkRemoveBasicCharges.Checked)
                //{
                //    BasicCharges = 0;
                //}
                //else
                //    BasicCharges = BCRate;

                BasicCharges = BCRate;
                GrossCommission = BusLib.CalculateCommission(Consideration, CommRate);
                Commission = (1 - NMIRebateRate) * GrossCommission;
                NMIRebate = NMIRebateRate * GrossCommission;

                Vat = BusLib.CalculateVAT(GrossCommission + BasicCharges, VatRate);

                InvestorProtection = BusLib.CalculateInvestorProtection(Consideration, InvestorRate);
                SecLevy = BusLib.CalculateSecLevy(Consideration, SecLevyRate);
                ZSELevy = BusLib.CalculateZSELevy(Consideration, ZSELevyRate);
                CSDLevy = CalculateCSDLevy(Consideration, CSDLevyRate);

                if (DealType == "SELL")
                    DealValue = Consideration - (Vat + GrossCommission + StampDuty + BasicCharges + SecLevy + CapitalGains + InvestorProtection + ZSELevy + CSDLevy);
                else if (DealType == "BUY")
                    DealValue = Consideration + (Vat + GrossCommission + StampDuty + BasicCharges + SecLevy + CapitalGains + InvestorProtection + ZSELevy + CSDLevy);
                else if (DealType == "BOVER")
                    DealValue = Consideration + (Vat + GrossCommission + StampDuty + BasicCharges + SecLevy + CapitalGains + InvestorProtection + ZSELevy + CSDLevy);

                txtDealValue.Text = Math.Round((float)DealValue, 2).ToString();
                txtConsideration.Text = Math.Round((float)Consideration, 2).ToString();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                //ScreenShot.EmailScreenShot(ex.ToString());
            }

        }

        private bool ValidateInput()
        {



            //changed 03092014 ABC
            //if (Convert.ToDateTime(dtpDealDate.Text) > DateTime.Now)
            //if (dtDealDate.DateTime > DateTime.Now)
            //{
            //    MessageBox.Show("Deal date cannot be greater than today's date", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
            //    dtDealDate.Focus();
            //    return false;
            //}
            //else
                //DealDate = Convert.ToDateTime(dtpDealDate.Text);
                DealDate = dtDealDate.DateTime;
            if (txtQty.Text == "")
            {
                MessageBox.Show("Deal quantity must have a value", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
                txtQty.Focus();
                return false;
            }

            if (txtClient.Text == "" && rdoBookover.Checked == false)
            {
                MessageBox.Show("Please, select client for that deal", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
                return false;
            }

            if (int.Parse(txtQty.Text) <= 0)
            {
                MessageBox.Show("Deal quantity must be greater than zero", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
                txtQty.Focus();
                return false;
            }

            if (double.Parse(txtPrice.Text) <= 0)
            {
                MessageBox.Show("Price must be greater than zero", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
                txtPrice.Focus();
                return false;
            }

            if (cmbAsset.Text == "")
            {
                MessageBox.Show("Please, enter the asset", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
                cmbAsset.Focus();
                return false;
            }

            if ((rdoBuy.Checked == false) && (rdoSell.Checked == false) && (rdoBookover.Checked == false))
            {
                MessageBox.Show("Please, select deal type", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
                rdoBuy.Focus();
                return false;
            }

            return true;
        }


        private void GetRates(string CNo)
        {
            try
            {
                if(Conn.State == ConnectionState.Closed)
                Conn.Open();
                using (SqlCommand RatesCmd = new SqlCommand(String.Format("GetClientRates '{0}'", CNo), Conn))
                {
                    SqlDataReader RatesReader = RatesCmd.ExecuteReader();
                    while (RatesReader.Read())
                    {
                        CommRate = double.Parse(RatesReader["commission"].ToString());
                        VatRate = double.Parse(RatesReader["vat"].ToString());
                        BCRate = double.Parse(RatesReader["basiccharges"].ToString());
                        StampDutyRate = double.Parse(RatesReader["stampduty"].ToString());
                        SecLevyRate = double.Parse(RatesReader["commissionerlevy"].ToString());
                        CapitalRate = double.Parse(RatesReader["capitalgains"].ToString());
                        ZSELevyRate = double.Parse(RatesReader["zselevy"].ToString());
                        InvestorRate = double.Parse(RatesReader["investorprotection"].ToString());
                        NMIRebateRate = double.Parse(RatesReader["nmirebate"].ToString());
                        CSDLevyRate = double.Parse(RatesReader["csdlevy"].ToString());
                    }
                }

            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                //ScreenShot.EmailScreenShot(ex.ToString());

            }
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

        private void btnClose_Click(object sender, EventArgs e)
        {
            //Close();
            txtClient.Text = ""; txtBuyer.Text = ""; txtCSD.Text = ""; txtCSDBuy.Text = ""; txtCSDSell.Text = "";
            txtDealValue.Text = ""; txtPrice.Text = ""; txtQty.Text = ""; txtSeller.Text = "";
            rdoBookover.Checked = false; rdoBuy.Checked = false; rdoSell.Checked = false;
            lblBuyer.Text = ""; lblSeller.Text = "";
            txtClient.Enabled = true; txtCSD.Enabled = true;
        }

        private void txtQty_Leave(object sender, EventArgs e)
        {
            if (txtQty.Text != "")
            {
                try
                {
                    int a = int.Parse(txtQty.Text);
                }
                catch (Exception)
                {
                    MessageBox.Show("Quantity appears to be invalid. No alphabetic characters are allowed", "Input Error", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    txtQty.Focus();
                }
            }
        }

        private void txtPrice_Leave(object sender, EventArgs e)
        {
            txtPrice.Text.Replace('.', ',');
            if (txtPrice.Text != "")
            {
                try
                {
                    //double a = double.Parse(txtPrice.Text.Replace(".",","));
                    //double a = double.Parse(txtPrice.Text);
                    double a = Convert.ToDouble(txtPrice.Text);
                    CalculateDealValue();
                }
                catch (Exception)
                {
                    MessageBox.Show("Price appears to be invalid. No alphabetic characters are allowed", "Input Error", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    txtPrice.Focus();
                    return;
                }
            }
        }

        private int GetDealNo()
        {
            try
            {
                if(Conn.State == ConnectionState.Closed)
                Conn.Open();
                using (SqlCommand DealNocmd = new SqlCommand("GetDealNo", Conn))
                {
                    SqlDataReader DealsReader = DealNocmd.ExecuteReader();
                    //string DealNo=dr["dealno"].ToString();
                    if (DealsReader.HasRows)
                        while (DealsReader.Read())
                            return (int.Parse(DealsReader["DealNo"].ToString()));
                }

                return (1);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                //ScreenShot.EmailScreenShot(ex.ToString());
                return 0;
            }
        }

        public void ClearForm()
        {
            txtQty.Text = "";
            txtPrice.Text = "";
            txtConsideration.Text = "";
            txtCSD.Text = "";
            cmbAsset.SelectedIndex = -1;
            rdoBuy.Checked = false;
            rdoSell.Checked = false;

            rdoBookover.Checked = false;
            lblSeller.Text = ""; lblBuyer.Text = "";
            txtCSDSell.Text = ""; txtCSDBuy.Text = "";
            txtCSD.Text = ""; txtSeller.Text = ""; txtBuyer.Text = "";

            txtCSD.Enabled = true; txtCSD.Enabled = true;
            
        }


        private void btnSave_Click(object sender, EventArgs e)
        {
         try
            {
             if(Conn.State == ConnectionState.Closed)
                Conn.Open();
                double Consideration, Commission, GrossCommission, BasicCharges, StampDuty = 0, Vat, SecLevy, ZSELevy, InvestorProtection, CapitalGains = 0, NMIRebate, CSDLevy;
                double Price;
                double DealValue = 0;
                double Qty = 0;
                //int DocNo;
                string DealType = "", DealNo = "";
                string ClientNo = "", Asset = "";
                string Reference = "";
                DateTime  CertDueBy;
            if (BusLib.TimeoutUsers(CurrentUser,false,Text)  == true)
            {
                MessageBox.Show("Your session has expired. Please, login again to use the system", "Access Denied", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            //if (BusLib.HasAccess(CurrentUser, "Post Deal Adjustments") == false)
            //{
            //    MessageBox.Show("You do not have permission to perform the selected task!", "Access Denied", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            //    return;
            //}

            if (dtDealDate.Text == "")
            {
                MessageBox.Show("Please enter deal date", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
                //dtpDealDate.Focus();
                return ;
            }
            //commented 03092014 ABC
            //if (BusLib.IsPeriodLocked(Convert.ToDateTime(dtpDealDate.Text)))
            if (BusLib.IsPeriodLocked(dtDealDate.DateTime))
            {
                MessageBox.Show("Accounting period currently locked. If you are not the one who locked it, please contact your administrator", "Locked Accounting Period", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                dtDealDate.Focus();
                return;
            }

            #region Check Permissions for Removing Charges
            //if ((chkRemoveBasicCharges.Checked) || (chkRemoveCommission.Checked))
            //{
            //    if (BusLib.HasAccess(CurrentUser, "Remove Charges") == false)
            //    {
            //        MessageBox.Show("You do not have permission to perform the selected task!", "Access Denied", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            //        return;
            //    }
            //}
            #endregion


            #region Check Permissions for Removing Charges
            //if ((chkRemoveBasicCharges.Checked) || (chkRemoveCommission.Checked))
            //{
            //    if (BusLib.HasAccess(CurrentUser, "Remove Charges") == false)
            //    {
            //        MessageBox.Show("You do not have permission to perform the selected task!", "Access Denied", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            //        return;
            //    }
            //}
            #endregion
                 
                
            //if (ValidateInput() == false)
            //{
            //   return;
            //}

            
            if (rdoSell.Checked )
            {
                DealType = "SELL"; 
            }
            else if (rdoBuy.Checked)
            {
                DealType = "BUY";
            }
                                            
            ClientNo = ClassGenLib.selectedClient;
            //Price=double.Parse(txtPrice.Text);
            txtPrice.Text = txtPrice.Text.Replace(',', '.');
            Price = Convert.ToDouble(txtPrice.Text);
            Qty = double.Parse(txtQty.Text);
            CertDueBy = GetSettlementDate(dtDealDate.DateTime);
            Asset = cmbAsset.Text;
                     
            Consideration = BusLib.CalculateConsideration(Qty,Price);
            

            GetRates(ClientNo);
            if (DealType == "SELL")
            {
                CapitalGains = BusLib.CalculateCapitalGains(Consideration, CapitalRate);
            }
            else if (DealType == "BUY")
            {
                StampDuty = BusLib.CalculateStampDuty(Consideration, StampDutyRate);
            }

            //if (chkRemoveCommission.Checked)
            //{

            //    #region Check Permissions for Removing Charges
            //    if ((chkRemoveBasicCharges.Checked) || (chkRemoveCommission.Checked))
            //    {
            //        if (BusLib.HasAccess(CurrentUser, "Remove Charges") == false)
            //        {
            //            MessageBox.Show("You do not have permission to perform the selected task!", "Access Denied", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            //            return;
            //        }
            //    }
            //    #endregion
            //    GrossCommission = 0;
            //    Commission = 0;
            //    NMIRebate = 0;
            //}
            //else
            {
                GrossCommission = BusLib.CalculateCommission(Consideration, CommRate);
                Commission = (1 - NMIRebateRate) * GrossCommission;
                NMIRebate = NMIRebateRate * GrossCommission;
            }
            //if (chkRemoveBasicCharges.Checked)
            //{
            //    #region Check Permissions for Removing Charges
            //    if ((chkRemoveBasicCharges.Checked) || (chkRemoveCommission.Checked))
            //    {
            //        if (BusLib.HasAccess(CurrentUser, "Remove Charges") == false)
            //        {
            //            MessageBox.Show("You do not have permission to perform the selected task!", "Access Denied", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            //            return;
            //        }
            //    }
            //    #endregion
            //      BasicCharges = 0;
            //}
            //else
                BasicCharges = BCRate;

           /*
            PROPRIETARY ACCOUNT CUSTOMIZATION FOR ABC STOCKBROKERS
            */
            SqlCommand cmdProprietary = new SqlCommand("select isnull(count(clientno), 0) from clients where clientno = '" + ClientNo + "' and category = 'PROPRIETARY'", Conn);
            int cntProprietary = Convert.ToInt16(cmdProprietary.ExecuteScalar());
            if (cntProprietary > 0)
            {
                cmdProprietary.CommandText = "select commission, vat from clientcategory where clientcategory = 'OTHER'";
                SqlDataReader rdProp = cmdProprietary.ExecuteReader();
                double commProprietary = 0;
                double vatProprietary = 0;
                while (rdProp.Read())
                {
                    commProprietary = Convert.ToDouble(rdProp[0].ToString());
                    vatProprietary = Convert.ToDouble(rdProp[1].ToString());
                }
                rdProp.Close();
                Vat = Consideration * commProprietary * vatProprietary / 10000;
            }
            else
            Vat = BusLib.CalculateVAT(GrossCommission + BasicCharges, VatRate);

            //check if the system is configured to capture CSD Number for a deal
            cmdProprietary.CommandText = "select CaptureCSDNo from tblSystemParams";
            sbyte CaptureCSD = Convert.ToSByte(cmdProprietary.ExecuteScalar());
            InvestorProtection = BusLib.CalculateInvestorProtection(Consideration, InvestorRate);
            SecLevy = BusLib.CalculateSecLevy(Consideration, SecLevyRate);
            ZSELevy = BusLib.CalculateZSELevy(Consideration, ZSELevyRate);
            CSDLevy = CalculateCSDLevy(Consideration, CSDLevyRate);

            if (DealType == "SELL")
                DealValue = Consideration -(Vat+ GrossCommission + StampDuty + BasicCharges + SecLevy + CapitalGains + InvestorProtection+ZSELevy+CSDLevy);
            else if (DealType == "BUY")
                DealValue = Consideration + (Vat + GrossCommission + StampDuty + BasicCharges + SecLevy + CapitalGains + InvestorProtection + ZSELevy+ CSDLevy);

            if (rdoBookover.Checked == false)
            {
                using (SqlCommand NewDealCmd = new SqlCommand())
                {
                    SqlCommand cmdPost = new SqlCommand("spPostDeal", Conn);
                    cmdPost.CommandType = CommandType.StoredProcedure;
                    cmdPost.CommandTimeout = 12000;
                    SqlParameter p1 = new SqlParameter("@dealdate", dtDealDate.Text);
                    SqlParameter p2 = new SqlParameter("@clientno", ClassGenLib.selectedClient);
                    SqlParameter p3 = new SqlParameter("@dealtype", DealType);
                    SqlParameter p4 = new SqlParameter("@qty", txtQty.Text);
                    SqlParameter p5 = new SqlParameter("@price", Price);
                    SqlParameter p6 = new SqlParameter("@asset", cmbAsset.Text.Substring(0, cmbAsset.Text.IndexOf("|") - 1));
                    SqlParameter p7 = new SqlParameter("@csdnumber", txtCSD.Text);
                    SqlParameter p8 = new SqlParameter("@user", ClassGenLib.username);
                    SqlParameter p9 = new SqlParameter("@noncustodial", chkCustodial.Checked);
                    SqlParameter p10 = new SqlParameter("@bookover", false);

                    cmdPost.Parameters.Add(p1); cmdPost.Parameters.Add(p2);
                    cmdPost.Parameters.Add(p3); cmdPost.Parameters.Add(p4);
                    cmdPost.Parameters.Add(p5); cmdPost.Parameters.Add(p6);
                    cmdPost.Parameters.Add(p7); cmdPost.Parameters.Add(p8);
                    cmdPost.Parameters.Add(p9); cmdPost.Parameters.Add(p10);

                    cmdPost.ExecuteNonQuery();

                    chkCustodial.Checked = false;
                }
            }

             if(rdoBookover.Checked == true)
             {
                 using (SqlCommand NewDealCmd = new SqlCommand())
                 {
                     //post BUY deal
                     SqlCommand cmdPost = new SqlCommand("spPostDeal", Conn);
                     cmdPost.CommandType = CommandType.StoredProcedure;
                     cmdPost.CommandTimeout = 12000;
                     SqlParameter p1 = new SqlParameter("@dealdate", dtDealDate.Text);
                     SqlParameter p2 = new SqlParameter("@clientno", Buyer);
                     SqlParameter p3 = new SqlParameter("@dealtype", "BUY");
                     SqlParameter p4 = new SqlParameter("@qty", txtQty.Text);
                     SqlParameter p5 = new SqlParameter("@price", Price);
                     SqlParameter p6 = new SqlParameter("@asset", cmbAsset.Text.Substring(0, cmbAsset.Text.IndexOf("|") - 1));
                     SqlParameter p7 = new SqlParameter("@csdnumber", CSDBuy);
                     SqlParameter p8 = new SqlParameter("@user", ClassGenLib.username);
                     SqlParameter p9 = new SqlParameter("@noncustodial", chkCustodial.Checked);
                     SqlParameter p10 = new SqlParameter("@bookover", true);

                     cmdPost.Parameters.Add(p1); cmdPost.Parameters.Add(p2);
                     cmdPost.Parameters.Add(p3); cmdPost.Parameters.Add(p4);
                     cmdPost.Parameters.Add(p5); cmdPost.Parameters.Add(p6);
                     cmdPost.Parameters.Add(p7); cmdPost.Parameters.Add(p8);
                     cmdPost.Parameters.Add(p9); cmdPost.Parameters.Add(p10); 

                     cmdPost.ExecuteNonQuery();

                     //post SELL deal
                     p2.Value = Seller;
                     p3.Value = "SELL";
                     p7.Value = CSDSell;

                     cmdPost.ExecuteNonQuery();
                     chkCustodial.Checked = false;
                 }
             }
             
                MessageBox.Show("Deal(s) posted successfully", "Deal Adjusted", MessageBoxButtons.OK, MessageBoxIcon.Information);
                rdoBookover.Checked = false;

             ClearForm();
           }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    //ScreenShot.EmailScreenShot(ex.ToString());
                }
            
        }

        private void NewDeal_Load(object sender, EventArgs e)
        {
            lblBuyer.Text = ""; lblSeller.Text = "";

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select assetcode+' | '+assetname from assets order by assetname", conn);
                    SqlDataReader rd = cmd.ExecuteReader();

                    while(rd.Read())
                    {
                        cmbAsset.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason : " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void txtPrice_KeyUp(object sender, KeyEventArgs e)
        {
            txtPrice.Text = txtPrice.Text.Replace(".", ",");
            txtPrice.SelectionStart = txtPrice.Text.Length;
            txtPrice.SelectionLength = 0;

            if (e.KeyCode == Keys.Enter)
            {
                txtCSD.Focus();
            }
        }

        private void cmbAsset_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Enter)
            {
                dtDealDate.Focus();
            }
        }

        private void dtDealDate_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
                txtQty.Focus();
        }

        private void dtDealDate_DateTimeChanged(object sender, EventArgs e)
        {
            if (dtDealDate.DateTime > DateTime.Now)
            {
                MessageBox.Show("Deal date cannot be greater than today's date", "Invalid Input", MessageBoxButtons.OK, MessageBoxIcon.Asterisk);
                dtDealDate.Focus();
                return;
            }
        }

        private void txtClient_KeyUp(object sender, KeyEventArgs e)
        {
            
        }

        private void txtQty_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Enter)
            {
                txtPrice.Focus();
            }
        }

        private void btnCancelBookover_Click(object sender, EventArgs e)
        {
            txtBuyer.Text = ""; txtSeller.Text = "";
            pnlBookover.Visible = false;
            rdoBookover.Checked = false;
            chkBookover.Checked = false;
            lblSeller.Text = "";
            lblBuyer.Text = "";
        }

        private void pictureEdit1_EditValueChanged(object sender, EventArgs e)
        {

        }

        private void chkBookover_CheckStateChanged(object sender, EventArgs e)
        {
            if (chkBookover.Checked == true)
            {
                if (txtBuyer.Text == "" && txtSeller.Text == "")
                {
                    MessageBox.Show("Please specify the buyer or the seller!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    chkBookover.Checked = false;
                    return;
                }

                if(txtBuyer.Text == "")
                {
                    txtBuyer.Text = txtSeller.Text;
                    Buyer = Seller;
                }

                if (txtSeller.Text == "")
                {
                    txtSeller.Text = txtBuyer.Text;
                    Seller = Buyer;
                }
            }
        }

        private void txtBuyer_ButtonClick(object sender, DevExpress.XtraEditors.Controls.ButtonPressedEventArgs e)
        {
            //get the seller client number
            ClientListing list = new ClientListing();
            list.ShowDialog();

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    string strSQL = "select clientname from vwClientListing where clientno = '"+ClassGenLib.selectedClient+"'";
                    SqlCommand cmd = new SqlCommand(strSQL, conn);

                    if (sender == txtBuyer)
                    {
                        Buyer = ClassGenLib.selectedClient;
                        txtBuyer.Text = cmd.ExecuteScalar().ToString();
                    }
                    else
                    {
                        Seller = ClassGenLib.selectedClient;
                        txtSeller.Text = cmd.ExecuteScalar().ToString();
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason : " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void radioButton1_CheckedChanged(object sender, EventArgs e)
        {
            if(rdoBookover.Checked == true)
            {
                pnlBookover.Visible = true;
            }
        }

        private void btnProceed_Click(object sender, EventArgs e)
        {
            if(txtBuyer.Text == "" && txtSeller.Text == "")
            {
                MessageBox.Show("Specify the buyer and seller for the bookover transaction!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            lblBuyer.Text = "Buyer: " + txtBuyer.Text;
            lblSeller.Text = "Seller: " + txtSeller.Text;
            CSDBuy = txtCSDBuy.Text;
            CSDSell = txtCSDSell.Text;
            txtSeller.Text = ""; txtBuyer.Text = "";
            pnlBookover.Visible = false;
            txtClient.Enabled = false;
            txtCSD.Enabled = false;
            txtClient.Text = txtCSDBuy.Text;
            cmbAsset.Focus();
        }

        private void chkCSD_CheckStateChanged(object sender, EventArgs e)
        {
            if(txtCSDBuy.Text == "" && txtCSDSell.Text == "")
            {
                MessageBox.Show("Specify at least one CSD number!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            if (txtCSDSell.Text != "" && txtCSDBuy.Text == "")
                txtCSDBuy.Text = txtCSDSell.Text;

            if (txtCSDSell.Text == "" && txtCSDBuy.Text != "")
                txtCSDSell.Text = txtCSDBuy.Text;
        }

    }
}
