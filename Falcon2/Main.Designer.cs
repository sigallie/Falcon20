namespace WindowsFormsApplication1
{
    partial class frmMain
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(frmMain));
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.loggedUser = new System.Windows.Forms.ToolStripStatusLabel();
            this.loggedTime = new System.Windows.Forms.ToolStripStatusLabel();
            this.lblNotify = new System.Windows.Forms.ToolStripStatusLabel();
            this.navBarControl1 = new DevExpress.XtraNavBar.NavBarControl();
            this.nvbFrontOffice = new DevExpress.XtraNavBar.NavBarGroup();
            this.btnBrokerDeal = new DevExpress.XtraNavBar.NavBarItem();
            this.btnNewDeal = new DevExpress.XtraNavBar.NavBarItem();
            this.btnViewDeals = new DevExpress.XtraNavBar.NavBarItem();
            this.navBarItem2 = new DevExpress.XtraNavBar.NavBarItem();
            this.grpClients = new DevExpress.XtraNavBar.NavBarGroup();
            this.btnTrades = new DevExpress.XtraNavBar.NavBarItem();
            this.btnNewClient = new DevExpress.XtraNavBar.NavBarItem();
            this.navBarItem1 = new DevExpress.XtraNavBar.NavBarItem();
            this.navBarGroup1 = new DevExpress.XtraNavBar.NavBarGroup();
            this.btnNewTxn = new DevExpress.XtraNavBar.NavBarItem();
            this.nvSettlement = new DevExpress.XtraNavBar.NavBarItem();
            this.btnApprove = new DevExpress.XtraNavBar.NavBarItem();
            this.btnTaxPayments = new DevExpress.XtraNavBar.NavBarItem();
            this.btnReview = new DevExpress.XtraNavBar.NavBarItem();
            this.mnuSharejobbing = new DevExpress.XtraNavBar.NavBarItem();
            this.grpReports = new DevExpress.XtraNavBar.NavBarGroup();
            this.btnOnScreenTB = new DevExpress.XtraNavBar.NavBarItem();
            this.btnPositions = new DevExpress.XtraNavBar.NavBarItem();
            this.btnLedgers = new DevExpress.XtraNavBar.NavBarItem();
            this.btnSTatements = new DevExpress.XtraNavBar.NavBarItem();
            this.btnCashbook = new DevExpress.XtraNavBar.NavBarItem();
            this.navBarItem4 = new DevExpress.XtraNavBar.NavBarItem();
            this.nbToptraders = new DevExpress.XtraNavBar.NavBarItem();
            this.btnBalances = new DevExpress.XtraNavBar.NavBarItem();
            this.grpAdmin = new DevExpress.XtraNavBar.NavBarGroup();
            this.btnUsers = new DevExpress.XtraNavBar.NavBarItem();
            this.navBarItem3 = new DevExpress.XtraNavBar.NavBarItem();
            this.imageList1 = new System.Windows.Forms.ImageList(this.components);
            this.navBarItem6 = new DevExpress.XtraNavBar.NavBarItem();
            this.tmApprovals = new System.Windows.Forms.Timer(this.components);
            this.statusStrip1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.navBarControl1)).BeginInit();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.loggedUser,
            this.loggedTime,
            this.lblNotify});
            this.statusStrip1.Location = new System.Drawing.Point(0, 521);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(900, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // loggedUser
            // 
            this.loggedUser.Name = "loggedUser";
            this.loggedUser.Size = new System.Drawing.Size(118, 17);
            this.loggedUser.Text = "toolStripStatusLabel1";
            // 
            // loggedTime
            // 
            this.loggedTime.Name = "loggedTime";
            this.loggedTime.Size = new System.Drawing.Size(118, 17);
            this.loggedTime.Text = "toolStripStatusLabel1";
            // 
            // lblNotify
            // 
            this.lblNotify.Font = new System.Drawing.Font("Segoe UI", 9F, System.Drawing.FontStyle.Bold);
            this.lblNotify.ForeColor = System.Drawing.Color.Red;
            this.lblNotify.Name = "lblNotify";
            this.lblNotify.Size = new System.Drawing.Size(0, 17);
            // 
            // navBarControl1
            // 
            this.navBarControl1.ActiveGroup = this.nvbFrontOffice;
            this.navBarControl1.Dock = System.Windows.Forms.DockStyle.Left;
            this.navBarControl1.Groups.AddRange(new DevExpress.XtraNavBar.NavBarGroup[] {
            this.grpClients,
            this.nvbFrontOffice,
            this.navBarGroup1,
            this.grpReports,
            this.grpAdmin});
            this.navBarControl1.Items.AddRange(new DevExpress.XtraNavBar.NavBarItem[] {
            this.btnViewDeals,
            this.btnBrokerDeal,
            this.btnNewDeal,
            this.btnOnScreenTB,
            this.btnPositions,
            this.btnLedgers,
            this.btnSTatements,
            this.btnNewTxn,
            this.btnApprove,
            this.btnTaxPayments,
            this.btnReview,
            this.btnTrades,
            this.btnNewClient,
            this.btnUsers,
            this.btnCashbook,
            this.navBarItem1,
            this.nvSettlement,
            this.mnuSharejobbing,
            this.navBarItem2,
            this.navBarItem3,
            this.navBarItem4,
            this.nbToptraders,
            this.btnBalances});
            this.navBarControl1.Location = new System.Drawing.Point(0, 0);
            this.navBarControl1.LookAndFeel.SkinName = "Office 2016 Colorful";
            this.navBarControl1.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.UltraFlat;
            this.navBarControl1.Name = "navBarControl1";
            this.navBarControl1.OptionsNavPane.ExpandedWidth = 172;
            this.navBarControl1.ShowIcons = DevExpress.Utils.DefaultBoolean.True;
            this.navBarControl1.Size = new System.Drawing.Size(172, 521);
            this.navBarControl1.SmallImages = this.imageList1;
            this.navBarControl1.StoreDefaultPaintStyleName = true;
            this.navBarControl1.TabIndex = 1;
            this.navBarControl1.Text = "navBarControl1";
            this.navBarControl1.Click += new System.EventHandler(this.navBarControl1_Click);
            // 
            // nvbFrontOffice
            // 
            this.nvbFrontOffice.Appearance.Font = new System.Drawing.Font("Arial", 10F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.nvbFrontOffice.Appearance.FontStyleDelta = System.Drawing.FontStyle.Bold;
            this.nvbFrontOffice.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.nvbFrontOffice.Appearance.Options.UseFont = true;
            this.nvbFrontOffice.Appearance.Options.UseForeColor = true;
            this.nvbFrontOffice.Caption = "Front Office";
            this.nvbFrontOffice.ItemLinks.AddRange(new DevExpress.XtraNavBar.NavBarItemLink[] {
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnBrokerDeal),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnNewDeal),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnViewDeals),
            new DevExpress.XtraNavBar.NavBarItemLink(this.navBarItem2)});
            this.nvbFrontOffice.Name = "nvbFrontOffice";
            // 
            // btnBrokerDeal
            // 
            this.btnBrokerDeal.Appearance.FontSizeDelta = 1;
            this.btnBrokerDeal.Appearance.Options.UseFont = true;
            this.btnBrokerDeal.Caption = "New Broker Deal";
            this.btnBrokerDeal.Name = "btnBrokerDeal";
            this.btnBrokerDeal.SmallImageIndex = 2;
            this.btnBrokerDeal.Visible = false;
            this.btnBrokerDeal.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnBrokerDeal_LinkClicked);
            // 
            // btnNewDeal
            // 
            this.btnNewDeal.Appearance.FontSizeDelta = 1;
            this.btnNewDeal.Caption = "New Deal";
            this.btnNewDeal.Name = "btnNewDeal";
            this.btnNewDeal.SmallImageIndex = 5;
            this.btnNewDeal.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnNewDeal_LinkClicked);
            // 
            // btnViewDeals
            // 
            this.btnViewDeals.Appearance.FontSizeDelta = 1;
            this.btnViewDeals.Appearance.Options.UseFont = true;
            this.btnViewDeals.Caption = "View Deals";
            this.btnViewDeals.Name = "btnViewDeals";
            this.btnViewDeals.SmallImageIndex = 4;
            this.btnViewDeals.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnViewDeals_LinkClicked);
            // 
            // navBarItem2
            // 
            this.navBarItem2.Caption = "Upload From File";
            this.navBarItem2.Name = "navBarItem2";
            this.navBarItem2.SmallImageIndex = 6;
            this.navBarItem2.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.navBarItem2_LinkClicked);
            // 
            // grpClients
            // 
            this.grpClients.Appearance.Font = new System.Drawing.Font("Arial", 10F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.grpClients.Appearance.FontStyleDelta = System.Drawing.FontStyle.Bold;
            this.grpClients.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.grpClients.Appearance.Options.UseFont = true;
            this.grpClients.Appearance.Options.UseForeColor = true;
            this.grpClients.Caption = "Clients";
            this.grpClients.Expanded = true;
            this.grpClients.GroupStyle = DevExpress.XtraNavBar.NavBarGroupStyle.SmallIconsText;
            this.grpClients.ItemLinks.AddRange(new DevExpress.XtraNavBar.NavBarItemLink[] {
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnTrades),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnNewClient),
            new DevExpress.XtraNavBar.NavBarItemLink(this.navBarItem1)});
            this.grpClients.Name = "grpClients";
            // 
            // btnTrades
            // 
            this.btnTrades.Caption = "Client Trades";
            this.btnTrades.Name = "btnTrades";
            this.btnTrades.SmallImageIndex = 1;
            this.btnTrades.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnTrades_LinkClicked);
            // 
            // btnNewClient
            // 
            this.btnNewClient.Caption = "New Client";
            this.btnNewClient.Name = "btnNewClient";
            this.btnNewClient.SmallImageIndex = 24;
            this.btnNewClient.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnNewClient_LinkClicked);
            // 
            // navBarItem1
            // 
            this.navBarItem1.Caption = "Edit Client Details";
            this.navBarItem1.Name = "navBarItem1";
            this.navBarItem1.SmallImageIndex = 25;
            this.navBarItem1.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.navBarItem1_LinkClicked);
            // 
            // navBarGroup1
            // 
            this.navBarGroup1.Appearance.Font = new System.Drawing.Font("Arial", 10F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.navBarGroup1.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.navBarGroup1.Appearance.Options.UseFont = true;
            this.navBarGroup1.Appearance.Options.UseForeColor = true;
            this.navBarGroup1.Caption = "Accounts";
            this.navBarGroup1.ItemLinks.AddRange(new DevExpress.XtraNavBar.NavBarItemLink[] {
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnNewTxn),
            new DevExpress.XtraNavBar.NavBarItemLink(this.nvSettlement),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnApprove),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnTaxPayments),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnReview),
            new DevExpress.XtraNavBar.NavBarItemLink(this.mnuSharejobbing)});
            this.navBarGroup1.Name = "navBarGroup1";
            this.navBarGroup1.TopVisibleLinkIndex = 2;
            // 
            // btnNewTxn
            // 
            this.btnNewTxn.Caption = "New Transaction";
            this.btnNewTxn.Name = "btnNewTxn";
            this.btnNewTxn.SmallImageIndex = 7;
            this.btnNewTxn.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnNewTxn_LinkClicked);
            // 
            // nvSettlement
            // 
            this.nvSettlement.Caption = "Settlement Transaction";
            this.nvSettlement.Name = "nvSettlement";
            this.nvSettlement.Visible = false;
            this.nvSettlement.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.nvSettlement_LinkClicked);
            // 
            // btnApprove
            // 
            this.btnApprove.Caption = "Approve Transaction";
            this.btnApprove.Name = "btnApprove";
            this.btnApprove.SmallImageIndex = 8;
            this.btnApprove.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnApprove_LinkClicked);
            // 
            // btnTaxPayments
            // 
            this.btnTaxPayments.Caption = "Tax Payments";
            this.btnTaxPayments.Name = "btnTaxPayments";
            this.btnTaxPayments.SmallImageIndex = 10;
            this.btnTaxPayments.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnTaxPayments_LinkClicked);
            // 
            // btnReview
            // 
            this.btnReview.Caption = "Review Transactions";
            this.btnReview.Name = "btnReview";
            this.btnReview.SmallImageIndex = 9;
            this.btnReview.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnReview_LinkClicked);
            // 
            // mnuSharejobbing
            // 
            this.mnuSharejobbing.Caption = "Sharejobbing";
            this.mnuSharejobbing.Name = "mnuSharejobbing";
            this.mnuSharejobbing.SmallImageIndex = 21;
            this.mnuSharejobbing.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.mnuSharejobbing_LinkClicked);
            // 
            // grpReports
            // 
            this.grpReports.Appearance.Font = new System.Drawing.Font("Arial", 10F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.grpReports.Appearance.FontStyleDelta = System.Drawing.FontStyle.Bold;
            this.grpReports.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.grpReports.Appearance.Options.UseFont = true;
            this.grpReports.Appearance.Options.UseForeColor = true;
            this.grpReports.Caption = "Reports";
            this.grpReports.Expanded = true;
            this.grpReports.GroupStyle = DevExpress.XtraNavBar.NavBarGroupStyle.SmallIconsText;
            this.grpReports.ItemLinks.AddRange(new DevExpress.XtraNavBar.NavBarItemLink[] {
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnOnScreenTB),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnPositions),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnLedgers),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnSTatements),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnCashbook),
            new DevExpress.XtraNavBar.NavBarItemLink(this.navBarItem4),
            new DevExpress.XtraNavBar.NavBarItemLink(this.nbToptraders),
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnBalances)});
            this.grpReports.Name = "grpReports";
            this.grpReports.TopVisibleLinkIndex = 4;
            // 
            // btnOnScreenTB
            // 
            this.btnOnScreenTB.Caption = "On-screen Trial Balance";
            this.btnOnScreenTB.Name = "btnOnScreenTB";
            this.btnOnScreenTB.SmallImageIndex = 20;
            this.btnOnScreenTB.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnOnScreenTB_LinkClicked);
            // 
            // btnPositions
            // 
            this.btnPositions.Caption = "Positions";
            this.btnPositions.Name = "btnPositions";
            this.btnPositions.SmallImageIndex = 19;
            this.btnPositions.Visible = false;
            // 
            // btnLedgers
            // 
            this.btnLedgers.Caption = "Ledgers";
            this.btnLedgers.Name = "btnLedgers";
            this.btnLedgers.SmallImageIndex = 15;
            this.btnLedgers.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnLedgers_LinkClicked);
            // 
            // btnSTatements
            // 
            this.btnSTatements.Caption = "Statements";
            this.btnSTatements.Name = "btnSTatements";
            this.btnSTatements.SmallImageIndex = 14;
            this.btnSTatements.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnSTatements_LinkClicked);
            // 
            // btnCashbook
            // 
            this.btnCashbook.Caption = "Cashbook";
            this.btnCashbook.Name = "btnCashbook";
            this.btnCashbook.SmallImageIndex = 16;
            this.btnCashbook.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnCashbook_LinkClicked);
            // 
            // navBarItem4
            // 
            this.navBarItem4.Caption = "Trading Summary";
            this.navBarItem4.Name = "navBarItem4";
            this.navBarItem4.SmallImageIndex = 17;
            this.navBarItem4.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.navBarItem4_LinkClicked);
            // 
            // nbToptraders
            // 
            this.nbToptraders.Caption = "Top Trading Clients";
            this.nbToptraders.Name = "nbToptraders";
            this.nbToptraders.SmallImageIndex = 18;
            this.nbToptraders.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.nbToptraders_LinkClicked);
            // 
            // btnBalances
            // 
            this.btnBalances.Caption = "Client Balances";
            this.btnBalances.Name = "btnBalances";
            this.btnBalances.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnBalances_LinkClicked);
            // 
            // grpAdmin
            // 
            this.grpAdmin.Appearance.Font = new System.Drawing.Font("Arial", 10F, System.Drawing.FontStyle.Bold);
            this.grpAdmin.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.grpAdmin.Appearance.Options.UseFont = true;
            this.grpAdmin.Appearance.Options.UseForeColor = true;
            this.grpAdmin.Caption = "Admin";
            this.grpAdmin.Expanded = true;
            this.grpAdmin.ItemLinks.AddRange(new DevExpress.XtraNavBar.NavBarItemLink[] {
            new DevExpress.XtraNavBar.NavBarItemLink(this.btnUsers),
            new DevExpress.XtraNavBar.NavBarItemLink(this.navBarItem3)});
            this.grpAdmin.Name = "grpAdmin";
            // 
            // btnUsers
            // 
            this.btnUsers.Caption = "Users";
            this.btnUsers.Name = "btnUsers";
            this.btnUsers.SmallImageIndex = 13;
            this.btnUsers.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.btnUsers_LinkClicked);
            // 
            // navBarItem3
            // 
            this.navBarItem3.Caption = "Settings";
            this.navBarItem3.Name = "navBarItem3";
            this.navBarItem3.SmallImageIndex = 12;
            this.navBarItem3.LinkClicked += new DevExpress.XtraNavBar.NavBarLinkEventHandler(this.Settings);
            // 
            // imageList1
            // 
            this.imageList1.ImageStream = ((System.Windows.Forms.ImageListStreamer)(resources.GetObject("imageList1.ImageStream")));
            this.imageList1.TransparentColor = System.Drawing.Color.Transparent;
            this.imageList1.Images.SetKeyName(0, "add-to-database.ico");
            this.imageList1.Images.SetKeyName(1, "imagesCAC4ZLNG.jpg");
            this.imageList1.Images.SetKeyName(2, "safe.ico");
            this.imageList1.Images.SetKeyName(3, "preview.ico");
            this.imageList1.Images.SetKeyName(4, "allocations.jpg");
            this.imageList1.Images.SetKeyName(5, "newdeal.png");
            this.imageList1.Images.SetKeyName(6, "upload.png");
            this.imageList1.Images.SetKeyName(7, "newtrans.jpg");
            this.imageList1.Images.SetKeyName(8, "approvetrans.png");
            this.imageList1.Images.SetKeyName(9, "reviewtrans.jpg");
            this.imageList1.Images.SetKeyName(10, "tax1.png");
            this.imageList1.Images.SetKeyName(11, "tax2.jpg");
            this.imageList1.Images.SetKeyName(12, "wheel.ico");
            this.imageList1.Images.SetKeyName(13, "users.jpg");
            this.imageList1.Images.SetKeyName(14, "ledger.png");
            this.imageList1.Images.SetKeyName(15, "statement.png");
            this.imageList1.Images.SetKeyName(16, "cashbook.jpg");
            this.imageList1.Images.SetKeyName(17, "summary.png");
            this.imageList1.Images.SetKeyName(18, "top.png");
            this.imageList1.Images.SetKeyName(19, "position.jpg");
            this.imageList1.Images.SetKeyName(20, "tb.png");
            this.imageList1.Images.SetKeyName(21, "sharejobbing.png");
            this.imageList1.Images.SetKeyName(22, "ledger.png");
            this.imageList1.Images.SetKeyName(23, "add-to-database.ico");
            this.imageList1.Images.SetKeyName(24, "newtrans.jpg");
            this.imageList1.Images.SetKeyName(25, "save.jpg");
            // 
            // navBarItem6
            // 
            this.navBarItem6.Appearance.FontSizeDelta = 1;
            this.navBarItem6.Appearance.Image = global::Falcon2.Properties.Resources.f_open;
            this.navBarItem6.Appearance.Options.UseFont = true;
            this.navBarItem6.Appearance.Options.UseImage = true;
            this.navBarItem6.Caption = "New Deal";
            this.navBarItem6.Name = "navBarItem6";
            this.navBarItem6.SmallImageIndex = 0;
            // 
            // tmApprovals
            // 
            this.tmApprovals.Enabled = true;
            this.tmApprovals.Tick += new System.EventHandler(this.tmApprovals_Tick);
            // 
            // frmMain
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(900, 543);
            this.Controls.Add(this.navBarControl1);
            this.Controls.Add(this.statusStrip1);
            this.Name = "frmMain";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Falcon - Home";
            this.WindowState = System.Windows.Forms.FormWindowState.Maximized;
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.frmMain_FormClosing);
            this.Load += new System.EventHandler(this.frmMain_Load);
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.navBarControl1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraNavBar.NavBarControl navBarControl1;
        private DevExpress.XtraNavBar.NavBarGroup nvbFrontOffice;
        private DevExpress.XtraNavBar.NavBarItem btnViewDeals;
        private DevExpress.XtraNavBar.NavBarItem btnBrokerDeal;
        private DevExpress.XtraNavBar.NavBarItem btnNewDeal;
        private DevExpress.XtraNavBar.NavBarGroup navBarGroup1;
        private DevExpress.XtraNavBar.NavBarGroup grpReports;
        private DevExpress.XtraNavBar.NavBarItem btnOnScreenTB;
        private DevExpress.XtraNavBar.NavBarItem btnPositions;
        private DevExpress.XtraNavBar.NavBarItem btnLedgers;
        private DevExpress.XtraNavBar.NavBarItem btnSTatements;
        private DevExpress.XtraNavBar.NavBarItem btnNewTxn;
        private DevExpress.XtraNavBar.NavBarItem btnApprove;
        private DevExpress.XtraNavBar.NavBarItem btnTaxPayments;
        private DevExpress.XtraNavBar.NavBarItem btnReview;
        private DevExpress.XtraNavBar.NavBarGroup grpClients;
        private DevExpress.XtraNavBar.NavBarItem btnTrades;
        private DevExpress.XtraNavBar.NavBarItem btnNewClient;
        private DevExpress.XtraNavBar.NavBarGroup grpAdmin;
        private DevExpress.XtraNavBar.NavBarItem btnUsers;
        private DevExpress.XtraNavBar.NavBarItem btnCashbook;
        private DevExpress.XtraNavBar.NavBarItem navBarItem1;
        private DevExpress.XtraNavBar.NavBarItem nvSettlement;
        private DevExpress.XtraNavBar.NavBarItem mnuSharejobbing;
        private DevExpress.XtraNavBar.NavBarItem navBarItem2;
        private DevExpress.XtraNavBar.NavBarItem navBarItem3;
        private System.Windows.Forms.ImageList imageList1;
        private DevExpress.XtraNavBar.NavBarItem navBarItem4;
        private DevExpress.XtraNavBar.NavBarItem nbToptraders;
        private DevExpress.XtraNavBar.NavBarItem navBarItem6;
        private System.Windows.Forms.ToolStripStatusLabel loggedUser;
        private System.Windows.Forms.ToolStripStatusLabel loggedTime;
        private System.Windows.Forms.Timer tmApprovals;
        private System.Windows.Forms.ToolStripStatusLabel lblNotify;
        private DevExpress.XtraNavBar.NavBarItem btnBalances;
    }
}