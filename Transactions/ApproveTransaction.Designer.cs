namespace Transactions
{
    partial class ApproveTransaction
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
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.xtraTabControl1 = new DevExpress.XtraTab.XtraTabControl();
            this.tbPayment = new DevExpress.XtraTab.XtraTabPage();
            this.btnPayClose = new DevExpress.XtraEditors.SimpleButton();
            this.btnPayApprove = new DevExpress.XtraEditors.SimpleButton();
            this.grdPayments = new DevExpress.XtraGrid.GridControl();
            this.mnuPayments = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.approveSeletedToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.approveAllToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.vwPayments = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.gridColumn1 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn2 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn3 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn4 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn5 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn6 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn7 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn8 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn9 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.repositoryItemCheckEdit1 = new DevExpress.XtraEditors.Repository.RepositoryItemCheckEdit();
            this.tbReceipt = new DevExpress.XtraTab.XtraTabPage();
            this.btnReceiptsClose = new DevExpress.XtraEditors.SimpleButton();
            this.btnReceiptsApprove = new DevExpress.XtraEditors.SimpleButton();
            this.grdReceipts = new DevExpress.XtraGrid.GridControl();
            this.vwReceipts = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.gridColumn10 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn11 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn12 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn13 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn14 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn15 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn16 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn17 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn18 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.repositoryItemCheckEdit2 = new DevExpress.XtraEditors.Repository.RepositoryItemCheckEdit();
            this.mnuReceipts = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.approveSelectedReceiptsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.approveAllReceiptsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            ((System.ComponentModel.ISupportInitialize)(this.xtraTabControl1)).BeginInit();
            this.xtraTabControl1.SuspendLayout();
            this.tbPayment.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.grdPayments)).BeginInit();
            this.mnuPayments.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.vwPayments)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.repositoryItemCheckEdit1)).BeginInit();
            this.tbReceipt.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.grdReceipts)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.vwReceipts)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.repositoryItemCheckEdit2)).BeginInit();
            this.mnuReceipts.SuspendLayout();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Location = new System.Drawing.Point(0, 463);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(934, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // xtraTabControl1
            // 
            this.xtraTabControl1.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.xtraTabControl1.Location = new System.Drawing.Point(0, 12);
            this.xtraTabControl1.LookAndFeel.SkinName = "Office 2013";
            this.xtraTabControl1.LookAndFeel.UseDefaultLookAndFeel = false;
            this.xtraTabControl1.Name = "xtraTabControl1";
            this.xtraTabControl1.SelectedTabPage = this.tbPayment;
            this.xtraTabControl1.Size = new System.Drawing.Size(934, 451);
            this.xtraTabControl1.TabIndex = 1;
            this.xtraTabControl1.TabPages.AddRange(new DevExpress.XtraTab.XtraTabPage[] {
            this.tbPayment,
            this.tbReceipt});
            // 
            // tbPayment
            // 
            this.tbPayment.Controls.Add(this.btnPayClose);
            this.tbPayment.Controls.Add(this.btnPayApprove);
            this.tbPayment.Controls.Add(this.grdPayments);
            this.tbPayment.Name = "tbPayment";
            this.tbPayment.Size = new System.Drawing.Size(932, 426);
            this.tbPayment.Text = "Payments Pending Approval";
            // 
            // btnPayClose
            // 
            this.btnPayClose.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnPayClose.Location = new System.Drawing.Point(811, 390);
            this.btnPayClose.Name = "btnPayClose";
            this.btnPayClose.Size = new System.Drawing.Size(75, 23);
            this.btnPayClose.TabIndex = 7;
            this.btnPayClose.Text = "Close";
            this.btnPayClose.Click += new System.EventHandler(this.btnPayClose_Click);
            // 
            // btnPayApprove
            // 
            this.btnPayApprove.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnPayApprove.Location = new System.Drawing.Point(730, 390);
            this.btnPayApprove.Name = "btnPayApprove";
            this.btnPayApprove.Size = new System.Drawing.Size(75, 23);
            this.btnPayApprove.TabIndex = 6;
            this.btnPayApprove.Text = "Approve";
            this.btnPayApprove.Click += new System.EventHandler(this.btnPayApprove_Click);
            // 
            // grdPayments
            // 
            this.grdPayments.ContextMenuStrip = this.mnuPayments;
            this.grdPayments.Location = new System.Drawing.Point(0, 3);
            this.grdPayments.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.UltraFlat;
            this.grdPayments.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grdPayments.MainView = this.vwPayments;
            this.grdPayments.Name = "grdPayments";
            this.grdPayments.RepositoryItems.AddRange(new DevExpress.XtraEditors.Repository.RepositoryItem[] {
            this.repositoryItemCheckEdit1});
            this.grdPayments.Size = new System.Drawing.Size(929, 381);
            this.grdPayments.TabIndex = 0;
            this.grdPayments.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.vwPayments});
            // 
            // mnuPayments
            // 
            this.mnuPayments.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.approveSeletedToolStripMenuItem,
            this.approveAllToolStripMenuItem});
            this.mnuPayments.Name = "mnuPayments";
            this.mnuPayments.Size = new System.Drawing.Size(167, 48);
            // 
            // approveSeletedToolStripMenuItem
            // 
            this.approveSeletedToolStripMenuItem.Name = "approveSeletedToolStripMenuItem";
            this.approveSeletedToolStripMenuItem.Size = new System.Drawing.Size(166, 22);
            this.approveSeletedToolStripMenuItem.Text = "Approve Selected";
            // 
            // approveAllToolStripMenuItem
            // 
            this.approveAllToolStripMenuItem.Name = "approveAllToolStripMenuItem";
            this.approveAllToolStripMenuItem.Size = new System.Drawing.Size(166, 22);
            this.approveAllToolStripMenuItem.Text = "Approve All";
            // 
            // vwPayments
            // 
            this.vwPayments.Columns.AddRange(new DevExpress.XtraGrid.Columns.GridColumn[] {
            this.gridColumn1,
            this.gridColumn2,
            this.gridColumn3,
            this.gridColumn4,
            this.gridColumn5,
            this.gridColumn6,
            this.gridColumn7,
            this.gridColumn8,
            this.gridColumn9});
            this.vwPayments.GridControl = this.grdPayments;
            this.vwPayments.Name = "vwPayments";
            this.vwPayments.OptionsSelection.MultiSelect = true;
            this.vwPayments.OptionsView.ShowFooter = true;
            this.vwPayments.OptionsView.ShowGroupPanel = false;
            // 
            // gridColumn1
            // 
            this.gridColumn1.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn1.AppearanceHeader.Options.UseFont = true;
            this.gridColumn1.Caption = "ReqID";
            this.gridColumn1.FieldName = "ReqID";
            this.gridColumn1.Name = "gridColumn1";
            this.gridColumn1.OptionsColumn.AllowEdit = false;
            this.gridColumn1.OptionsColumn.ReadOnly = true;
            this.gridColumn1.Visible = true;
            this.gridColumn1.VisibleIndex = 0;
            // 
            // gridColumn2
            // 
            this.gridColumn2.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn2.AppearanceHeader.Options.UseFont = true;
            this.gridColumn2.Caption = "Client #";
            this.gridColumn2.FieldName = "ClientNo";
            this.gridColumn2.Name = "gridColumn2";
            this.gridColumn2.OptionsColumn.AllowEdit = false;
            this.gridColumn2.OptionsColumn.ReadOnly = true;
            this.gridColumn2.Visible = true;
            this.gridColumn2.VisibleIndex = 1;
            // 
            // gridColumn3
            // 
            this.gridColumn3.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn3.AppearanceHeader.Options.UseFont = true;
            this.gridColumn3.Caption = "Payee";
            this.gridColumn3.FieldName = "client";
            this.gridColumn3.Name = "gridColumn3";
            this.gridColumn3.OptionsColumn.AllowEdit = false;
            this.gridColumn3.OptionsColumn.ReadOnly = true;
            this.gridColumn3.Visible = true;
            this.gridColumn3.VisibleIndex = 2;
            // 
            // gridColumn4
            // 
            this.gridColumn4.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn4.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn4.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn4.AppearanceHeader.Options.UseFont = true;
            this.gridColumn4.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn4.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn4.Caption = "Amount";
            this.gridColumn4.DisplayFormat.FormatString = "c2";
            this.gridColumn4.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Custom;
            this.gridColumn4.FieldName = "Amount";
            this.gridColumn4.Name = "gridColumn4";
            this.gridColumn4.OptionsColumn.AllowEdit = false;
            this.gridColumn4.OptionsColumn.ReadOnly = true;
            this.gridColumn4.Visible = true;
            this.gridColumn4.VisibleIndex = 3;
            // 
            // gridColumn5
            // 
            this.gridColumn5.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn5.AppearanceHeader.Options.UseFont = true;
            this.gridColumn5.Caption = "Deal #";
            this.gridColumn5.FieldName = "DealNo";
            this.gridColumn5.Name = "gridColumn5";
            this.gridColumn5.OptionsColumn.AllowEdit = false;
            this.gridColumn5.OptionsColumn.ReadOnly = true;
            this.gridColumn5.Visible = true;
            this.gridColumn5.VisibleIndex = 4;
            // 
            // gridColumn6
            // 
            this.gridColumn6.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn6.AppearanceHeader.Options.UseFont = true;
            this.gridColumn6.Caption = "Trans Date";
            this.gridColumn6.FieldName = "TransDate";
            this.gridColumn6.Name = "gridColumn6";
            this.gridColumn6.OptionsColumn.AllowEdit = false;
            this.gridColumn6.OptionsColumn.ReadOnly = true;
            this.gridColumn6.Visible = true;
            this.gridColumn6.VisibleIndex = 5;
            // 
            // gridColumn7
            // 
            this.gridColumn7.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn7.AppearanceHeader.Options.UseFont = true;
            this.gridColumn7.Caption = "Description";
            this.gridColumn7.CustomizationCaption = "Cashbook";
            this.gridColumn7.FieldName = "DESCRIPTION";
            this.gridColumn7.Name = "gridColumn7";
            this.gridColumn7.OptionsColumn.AllowEdit = false;
            this.gridColumn7.OptionsColumn.ReadOnly = true;
            this.gridColumn7.Visible = true;
            this.gridColumn7.VisibleIndex = 6;
            // 
            // gridColumn8
            // 
            this.gridColumn8.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn8.AppearanceHeader.Options.UseFont = true;
            this.gridColumn8.Caption = "Captured by";
            this.gridColumn8.FieldName = "LOGIN";
            this.gridColumn8.Name = "gridColumn8";
            this.gridColumn8.OptionsColumn.AllowEdit = false;
            this.gridColumn8.OptionsColumn.ReadOnly = true;
            this.gridColumn8.Visible = true;
            this.gridColumn8.VisibleIndex = 7;
            // 
            // gridColumn9
            // 
            this.gridColumn9.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn9.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Center;
            this.gridColumn9.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn9.AppearanceHeader.Options.UseFont = true;
            this.gridColumn9.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn9.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Center;
            this.gridColumn9.Caption = "Approve";
            this.gridColumn9.ColumnEdit = this.repositoryItemCheckEdit1;
            this.gridColumn9.Name = "gridColumn9";
            this.gridColumn9.Visible = true;
            this.gridColumn9.VisibleIndex = 8;
            // 
            // repositoryItemCheckEdit1
            // 
            this.repositoryItemCheckEdit1.AutoHeight = false;
            this.repositoryItemCheckEdit1.Name = "repositoryItemCheckEdit1";
            this.repositoryItemCheckEdit1.NullStyle = DevExpress.XtraEditors.Controls.StyleIndeterminate.Inactive;
            // 
            // tbReceipt
            // 
            this.tbReceipt.Controls.Add(this.btnReceiptsClose);
            this.tbReceipt.Controls.Add(this.btnReceiptsApprove);
            this.tbReceipt.Controls.Add(this.grdReceipts);
            this.tbReceipt.Name = "tbReceipt";
            this.tbReceipt.Size = new System.Drawing.Size(932, 426);
            this.tbReceipt.Text = "Receipts Pending Approval";
            // 
            // btnReceiptsClose
            // 
            this.btnReceiptsClose.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnReceiptsClose.Location = new System.Drawing.Point(788, 398);
            this.btnReceiptsClose.Name = "btnReceiptsClose";
            this.btnReceiptsClose.Size = new System.Drawing.Size(75, 23);
            this.btnReceiptsClose.TabIndex = 3;
            this.btnReceiptsClose.Text = "Close";
            this.btnReceiptsClose.Click += new System.EventHandler(this.btnReceiptsClose_Click);
            // 
            // btnReceiptsApprove
            // 
            this.btnReceiptsApprove.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnReceiptsApprove.Location = new System.Drawing.Point(707, 398);
            this.btnReceiptsApprove.Name = "btnReceiptsApprove";
            this.btnReceiptsApprove.Size = new System.Drawing.Size(75, 23);
            this.btnReceiptsApprove.TabIndex = 2;
            this.btnReceiptsApprove.Text = "Approve";
            this.btnReceiptsApprove.Click += new System.EventHandler(this.btnPayApprove_Click);
            // 
            // grdReceipts
            // 
            this.grdReceipts.ContextMenuStrip = this.mnuPayments;
            this.grdReceipts.Location = new System.Drawing.Point(0, 3);
            this.grdReceipts.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.UltraFlat;
            this.grdReceipts.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grdReceipts.MainView = this.vwReceipts;
            this.grdReceipts.Name = "grdReceipts";
            this.grdReceipts.RepositoryItems.AddRange(new DevExpress.XtraEditors.Repository.RepositoryItem[] {
            this.repositoryItemCheckEdit2});
            this.grdReceipts.Size = new System.Drawing.Size(929, 389);
            this.grdReceipts.TabIndex = 1;
            this.grdReceipts.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.vwReceipts});
            // 
            // vwReceipts
            // 
            this.vwReceipts.Columns.AddRange(new DevExpress.XtraGrid.Columns.GridColumn[] {
            this.gridColumn10,
            this.gridColumn11,
            this.gridColumn12,
            this.gridColumn13,
            this.gridColumn14,
            this.gridColumn15,
            this.gridColumn16,
            this.gridColumn17,
            this.gridColumn18});
            this.vwReceipts.GridControl = this.grdReceipts;
            this.vwReceipts.Name = "vwReceipts";
            this.vwReceipts.OptionsSelection.MultiSelect = true;
            this.vwReceipts.OptionsView.ShowFooter = true;
            this.vwReceipts.OptionsView.ShowGroupPanel = false;
            // 
            // gridColumn10
            // 
            this.gridColumn10.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn10.AppearanceHeader.Options.UseFont = true;
            this.gridColumn10.Caption = "ReqID";
            this.gridColumn10.FieldName = "ReqID";
            this.gridColumn10.Name = "gridColumn10";
            this.gridColumn10.Visible = true;
            this.gridColumn10.VisibleIndex = 0;
            // 
            // gridColumn11
            // 
            this.gridColumn11.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn11.AppearanceHeader.Options.UseFont = true;
            this.gridColumn11.Caption = "Client #";
            this.gridColumn11.FieldName = "ClientNo";
            this.gridColumn11.Name = "gridColumn11";
            this.gridColumn11.Visible = true;
            this.gridColumn11.VisibleIndex = 1;
            // 
            // gridColumn12
            // 
            this.gridColumn12.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn12.AppearanceHeader.Options.UseFont = true;
            this.gridColumn12.Caption = "Recipient";
            this.gridColumn12.FieldName = "client";
            this.gridColumn12.Name = "gridColumn12";
            this.gridColumn12.Visible = true;
            this.gridColumn12.VisibleIndex = 2;
            // 
            // gridColumn13
            // 
            this.gridColumn13.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn13.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn13.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn13.AppearanceHeader.Options.UseFont = true;
            this.gridColumn13.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn13.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn13.Caption = "Amount";
            this.gridColumn13.DisplayFormat.FormatString = "c2";
            this.gridColumn13.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Custom;
            this.gridColumn13.FieldName = "Amount";
            this.gridColumn13.Name = "gridColumn13";
            this.gridColumn13.Visible = true;
            this.gridColumn13.VisibleIndex = 3;
            // 
            // gridColumn14
            // 
            this.gridColumn14.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn14.AppearanceHeader.Options.UseFont = true;
            this.gridColumn14.Caption = "Deal #";
            this.gridColumn14.FieldName = "DealNo";
            this.gridColumn14.Name = "gridColumn14";
            this.gridColumn14.Visible = true;
            this.gridColumn14.VisibleIndex = 4;
            // 
            // gridColumn15
            // 
            this.gridColumn15.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn15.AppearanceHeader.Options.UseFont = true;
            this.gridColumn15.Caption = "Trans Date";
            this.gridColumn15.FieldName = "TransDate";
            this.gridColumn15.Name = "gridColumn15";
            this.gridColumn15.Visible = true;
            this.gridColumn15.VisibleIndex = 5;
            // 
            // gridColumn16
            // 
            this.gridColumn16.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn16.AppearanceHeader.Options.UseFont = true;
            this.gridColumn16.Caption = "Description";
            this.gridColumn16.CustomizationCaption = "Cashbook";
            this.gridColumn16.FieldName = "DESCRIPTION";
            this.gridColumn16.Name = "gridColumn16";
            this.gridColumn16.Visible = true;
            this.gridColumn16.VisibleIndex = 6;
            // 
            // gridColumn17
            // 
            this.gridColumn17.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn17.AppearanceHeader.Options.UseFont = true;
            this.gridColumn17.Caption = "Captured by";
            this.gridColumn17.FieldName = "LOGIN";
            this.gridColumn17.Name = "gridColumn17";
            this.gridColumn17.Visible = true;
            this.gridColumn17.VisibleIndex = 7;
            // 
            // gridColumn18
            // 
            this.gridColumn18.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn18.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Center;
            this.gridColumn18.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn18.AppearanceHeader.Options.UseFont = true;
            this.gridColumn18.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn18.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Center;
            this.gridColumn18.Caption = "Approve";
            this.gridColumn18.ColumnEdit = this.repositoryItemCheckEdit2;
            this.gridColumn18.Name = "gridColumn18";
            this.gridColumn18.Visible = true;
            this.gridColumn18.VisibleIndex = 8;
            // 
            // repositoryItemCheckEdit2
            // 
            this.repositoryItemCheckEdit2.AutoHeight = false;
            this.repositoryItemCheckEdit2.Name = "repositoryItemCheckEdit2";
            this.repositoryItemCheckEdit2.NullStyle = DevExpress.XtraEditors.Controls.StyleIndeterminate.Inactive;
            // 
            // mnuReceipts
            // 
            this.mnuReceipts.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.approveSelectedReceiptsToolStripMenuItem,
            this.approveAllReceiptsToolStripMenuItem});
            this.mnuReceipts.Name = "mnuReceipts";
            this.mnuReceipts.Size = new System.Drawing.Size(214, 48);
            // 
            // approveSelectedReceiptsToolStripMenuItem
            // 
            this.approveSelectedReceiptsToolStripMenuItem.Name = "approveSelectedReceiptsToolStripMenuItem";
            this.approveSelectedReceiptsToolStripMenuItem.Size = new System.Drawing.Size(213, 22);
            this.approveSelectedReceiptsToolStripMenuItem.Text = "Approve Selected Receipts";
            // 
            // approveAllReceiptsToolStripMenuItem
            // 
            this.approveAllReceiptsToolStripMenuItem.Name = "approveAllReceiptsToolStripMenuItem";
            this.approveAllReceiptsToolStripMenuItem.Size = new System.Drawing.Size(213, 22);
            this.approveAllReceiptsToolStripMenuItem.Text = "Approve All Receipts";
            // 
            // ApproveTransaction
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(934, 485);
            this.Controls.Add(this.xtraTabControl1);
            this.Controls.Add(this.statusStrip1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "ApproveTransaction";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Approve Transactions";
            this.Load += new System.EventHandler(this.ApproveTransaction_Load);
            ((System.ComponentModel.ISupportInitialize)(this.xtraTabControl1)).EndInit();
            this.xtraTabControl1.ResumeLayout(false);
            this.tbPayment.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.grdPayments)).EndInit();
            this.mnuPayments.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.vwPayments)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.repositoryItemCheckEdit1)).EndInit();
            this.tbReceipt.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.grdReceipts)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.vwReceipts)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.repositoryItemCheckEdit2)).EndInit();
            this.mnuReceipts.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraTab.XtraTabControl xtraTabControl1;
        private DevExpress.XtraTab.XtraTabPage tbPayment;
        private DevExpress.XtraGrid.GridControl grdPayments;
        private System.Windows.Forms.ContextMenuStrip mnuPayments;
        private System.Windows.Forms.ToolStripMenuItem approveSeletedToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem approveAllToolStripMenuItem;
        private DevExpress.XtraGrid.Views.Grid.GridView vwPayments;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn1;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn2;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn3;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn4;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn5;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn6;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn7;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn8;
        private DevExpress.XtraTab.XtraTabPage tbReceipt;
        private System.Windows.Forms.ContextMenuStrip mnuReceipts;
        private System.Windows.Forms.ToolStripMenuItem approveSelectedReceiptsToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem approveAllReceiptsToolStripMenuItem;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn9;
        private DevExpress.XtraEditors.Repository.RepositoryItemCheckEdit repositoryItemCheckEdit1;
        private DevExpress.XtraGrid.GridControl grdReceipts;
        private DevExpress.XtraGrid.Views.Grid.GridView vwReceipts;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn10;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn11;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn12;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn13;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn14;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn15;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn16;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn17;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn18;
        private DevExpress.XtraEditors.Repository.RepositoryItemCheckEdit repositoryItemCheckEdit2;
        private DevExpress.XtraEditors.SimpleButton btnReceiptsClose;
        private DevExpress.XtraEditors.SimpleButton btnReceiptsApprove;
        private DevExpress.XtraEditors.SimpleButton btnPayClose;
        private DevExpress.XtraEditors.SimpleButton btnPayApprove;
    }
}