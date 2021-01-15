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
using System.Data.SqlClient;

using Deals;
using Transactions;
using ViewReports;
using Reports;
using Admin;

using Clients;
using GenLib;
using DBUtils;

namespace WindowsFormsApplication1
{
    public partial class frmMain : Form
    {
        public frmMain()
        {
            InitializeComponent();
        }

        private void frmMain_Load(object sender, EventArgs e)
        {
            loggedUser.Text = "Logged user : "+ ClassGenLib.username;
            loggedTime.Text = "  Logged in at: " + DateTime.Now.ToString();
        }

        private void navBarControl1_Click(object sender, EventArgs e)
        {

        }

        private void btnNewDeal_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "POST NEW DEAL") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            NewDeal nwdeal = new NewDeal();
            nwdeal.ShowDialog();
        }

        private void btnViewDeals_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "VIEW DEAL ALLOCATIONS") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            ViewDeals vdeal = new ViewDeals();
            vdeal.ShowDialog();
        }

        private void btnBrokerDeal_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            NewBrokerDeal bdeal = new NewBrokerDeal();
            bdeal.ShowDialog();
        }

        private void btnNewTxn_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "POST NEW TRANSACTION") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            Transactions.NewTransaction ntxn = new Transactions.NewTransaction();
            ntxn.ShowDialog();
        }

        private void btnSTatements_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "VIEW CLIENT REPORTS") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            Reports.frmClientStatement stmt = new Reports.frmClientStatement();
            stmt.ShowDialog();
        }

        private void btnTrades_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "VIEW CLIENT TRADES") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            ClientTrades trades = new ClientTrades();
            trades.ShowDialog();
        }

        private void btnLedgers_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "VIEW LEDGERS") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            SelectReport srpt = new SelectReport(1);
            srpt.ShowDialog();
        }

        private void btnApprove_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "APPROVE TRANSACTION") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            ApproveTransaction atxn = new ApproveTransaction();
            atxn.ShowDialog();
        }

        private void frmMain_FormClosing(object sender, FormClosingEventArgs e)
        {
            Application.Exit();
        }

        private void btnOnScreenTB_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "VIEW TRIAL BALANCE") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            Transactions.OnscreenTB onTB = new Transactions.OnscreenTB();
            onTB.ShowDialog();
        }

        private void btnTaxPayments_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "POST TAX PAYMENT") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            TaxPayments tax = new TaxPayments();
            tax.ShowDialog();
        }

        private void btnUsers_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            UserListsing lst = new UserListsing();
            lst.ShowDialog();
        }

        private void btnNewClient_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "ADD NEW CLIENT") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            NewClient client = new NewClient("0");
            client.ShowDialog();
        }

        private void btnCashbook_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "VIEW CASHBOOKS") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            ViewCashBook vbook = new ViewCashBook();
            vbook.ShowDialog();
        }

        private void navBarItem1_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "EDIT CLIENT DETAILS") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            ClientListing lst = new ClientListing();
            lst.ShowDialog();

            NewClient client = new NewClient(GenLib.ClassGenLib.selectedClient);
            client.ShowDialog();
        }

        private void nvSettlement_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            SettlementTransaction strans = new SettlementTransaction();
            strans.ShowDialog();
        }

        private void mnuSharejobbing_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            SharejobbingSummary sharesum = new SharejobbingSummary();
            sharesum.ShowDialog();
        }

        private void navBarItem2_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "UPLOAD DEALS FROM FILE") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            DealsFromFile dfile = new DealsFromFile();
            dfile.ShowDialog();
        }

        private void Settings(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            SystemAdministration sysad = new SystemAdministration();
            sysad.ShowDialog();
        }

        private void navBarItem4_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "VIEW TRADING SUMMARY") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            Reports.TradingSummary trade = new Reports.TradingSummary();
            trade.ShowDialog();
        }

        private void nbToptraders_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "VIEW TOP TRADING CLIENTS") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            Toptraders top = new Toptraders();
            top.ShowDialog();
        }

        private void btnReview_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "REVIEW TRANSACTIONS") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            TransactionReview trev = new TransactionReview();
            trev.ShowDialog();
        }

        private void tmApprovals_Tick(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    
                    if (ClassDBUtils.IsAllowed(ClassGenLib.username, "APPROVE TRANSACTION") == true)
                    {
                        SqlCommand cmdNotify = new SqlCommand("select count(reqid) from requisitions where approved = 0 and cancelled = 0", conn);
                        int approvals = Convert.ToInt32(cmdNotify.ExecuteScalar());
                        if (approvals > 0)
                            //MessageBox.Show("approvals");
                            lblNotify.Text = "You have pending approvals";
                        else
                            lblNotify.Text = "";
                    }
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Failed to connect to database! " + ex.Message);
                }
            }
        }

        private void btnBalances_LinkClicked(object sender, DevExpress.XtraNavBar.NavBarLinkEventArgs e)
        {
            ClientBalances cbal = new ClientBalances();
            cbal.ShowDialog();
        }
    }
}
