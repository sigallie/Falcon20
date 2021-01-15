namespace Transactions
{
    partial class TransactionReview
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
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.xtraTabControl1 = new DevExpress.XtraTab.XtraTabControl();
            this.tbPayment = new DevExpress.XtraTab.XtraTabPage();
            this.grdPayments = new DevExpress.XtraGrid.GridControl();
            this.mnuPayments = new System.Windows.Forms.ContextMenuStrip();
            this.reprintPaymentRequisitionToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
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
            this.grdReceipts = new DevExpress.XtraGrid.GridControl();
            this.mnuReceipt = new System.Windows.Forms.ContextMenuStrip();
            this.reprintReceiptToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
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
            ((System.ComponentModel.ISupportInitialize)(this.xtraTabControl1)).BeginInit();
            this.xtraTabControl1.SuspendLayout();
            this.tbPayment.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.grdPayments)).BeginInit();
            this.mnuPayments.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.vwPayments)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.repositoryItemCheckEdit1)).BeginInit();
            this.tbReceipt.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.grdReceipts)).BeginInit();
            this.mnuReceipt.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.vwReceipts)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.repositoryItemCheckEdit2)).BeginInit();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Location = new System.Drawing.Point(0, 441);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(1019, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // xtraTabControl1
            // 
            this.xtraTabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.xtraTabControl1.Location = new System.Drawing.Point(0, 0);
            this.xtraTabControl1.LookAndFeel.SkinName = "Office 2013";
            this.xtraTabControl1.LookAndFeel.UseDefaultLookAndFeel = false;
            this.xtraTabControl1.Name = "xtraTabControl1";
            this.xtraTabControl1.SelectedTabPage = this.tbPayment;
            this.xtraTabControl1.Size = new System.Drawing.Size(1019, 441);
            this.xtraTabControl1.TabIndex = 2;
            this.xtraTabControl1.TabPages.AddRange(new DevExpress.XtraTab.XtraTabPage[] {
            this.tbPayment,
            this.tbReceipt});
            // 
            // tbPayment
            // 
            this.tbPayment.Controls.Add(this.grdPayments);
            this.tbPayment.Name = "tbPayment";
            this.tbPayment.Size = new System.Drawing.Size(1017, 416);
            this.tbPayment.Text = "Payments";
            // 
            // grdPayments
            // 
            this.grdPayments.ContextMenuStrip = this.mnuPayments;
            this.grdPayments.Dock = System.Windows.Forms.DockStyle.Fill;
            this.grdPayments.Location = new System.Drawing.Point(0, 0);
            this.grdPayments.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.UltraFlat;
            this.grdPayments.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grdPayments.MainView = this.vwPayments;
            this.grdPayments.Name = "grdPayments";
            this.grdPayments.RepositoryItems.AddRange(new DevExpress.XtraEditors.Repository.RepositoryItem[] {
            this.repositoryItemCheckEdit1});
            this.grdPayments.Size = new System.Drawing.Size(1017, 416);
            this.grdPayments.TabIndex = 0;
            this.grdPayments.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.vwPayments});
            // 
            // mnuPayments
            // 
            this.mnuPayments.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.reprintPaymentRequisitionToolStripMenuItem});
            this.mnuPayments.Name = "mnuPayments";
            this.mnuPayments.Size = new System.Drawing.Size(225, 26);
            // 
            // reprintPaymentRequisitionToolStripMenuItem
            // 
            this.reprintPaymentRequisitionToolStripMenuItem.Name = "reprintPaymentRequisitionToolStripMenuItem";
            this.reprintPaymentRequisitionToolStripMenuItem.Size = new System.Drawing.Size(224, 22);
            this.reprintPaymentRequisitionToolStripMenuItem.Text = "Reprint Payment Requisition";
            this.reprintPaymentRequisitionToolStripMenuItem.Click += new System.EventHandler(this.reprintPaymentRequisitionToolStripMenuItem_Click);
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
            this.gridColumn1.Caption = "Transaction ID";
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
            this.gridColumn9.Caption = "Approved By";
            this.gridColumn9.FieldName = "APPROVEDBY";
            this.gridColumn9.Name = "gridColumn9";
            this.gridColumn9.OptionsColumn.AllowEdit = false;
            this.gridColumn9.OptionsColumn.ReadOnly = true;
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
            this.tbReceipt.Controls.Add(this.grdReceipts);
            this.tbReceipt.Name = "tbReceipt";
            this.tbReceipt.Size = new System.Drawing.Size(1017, 416);
            this.tbReceipt.Text = "Receipts";
            // 
            // grdReceipts
            // 
            this.grdReceipts.ContextMenuStrip = this.mnuReceipt;
            this.grdReceipts.Dock = System.Windows.Forms.DockStyle.Fill;
            this.grdReceipts.Location = new System.Drawing.Point(0, 0);
            this.grdReceipts.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.UltraFlat;
            this.grdReceipts.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grdReceipts.MainView = this.vwReceipts;
            this.grdReceipts.Name = "grdReceipts";
            this.grdReceipts.RepositoryItems.AddRange(new DevExpress.XtraEditors.Repository.RepositoryItem[] {
            this.repositoryItemCheckEdit2});
            this.grdReceipts.Size = new System.Drawing.Size(1017, 416);
            this.grdReceipts.TabIndex = 1;
            this.grdReceipts.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.vwReceipts});
            // 
            // mnuReceipt
            // 
            this.mnuReceipt.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.reprintReceiptToolStripMenuItem});
            this.mnuReceipt.Name = "mnuReceipt";
            this.mnuReceipt.Size = new System.Drawing.Size(155, 26);
            // 
            // reprintReceiptToolStripMenuItem
            // 
            this.reprintReceiptToolStripMenuItem.Name = "reprintReceiptToolStripMenuItem";
            this.reprintReceiptToolStripMenuItem.Size = new System.Drawing.Size(154, 22);
            this.reprintReceiptToolStripMenuItem.Text = "Reprint Receipt";
            this.reprintReceiptToolStripMenuItem.Click += new System.EventHandler(this.reprintReceiptToolStripMenuItem_Click);
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
            this.gridColumn10.Caption = "Transaction ID";
            this.gridColumn10.FieldName = "ReqID";
            this.gridColumn10.Name = "gridColumn10";
            this.gridColumn10.OptionsColumn.AllowEdit = false;
            this.gridColumn10.OptionsColumn.ReadOnly = true;
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
            this.gridColumn11.OptionsColumn.AllowEdit = false;
            this.gridColumn11.OptionsColumn.ReadOnly = true;
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
            this.gridColumn12.OptionsColumn.AllowEdit = false;
            this.gridColumn12.OptionsColumn.ReadOnly = true;
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
            this.gridColumn13.OptionsColumn.AllowEdit = false;
            this.gridColumn13.OptionsColumn.ReadOnly = true;
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
            this.gridColumn14.OptionsColumn.AllowEdit = false;
            this.gridColumn14.OptionsColumn.ReadOnly = true;
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
            this.gridColumn15.OptionsColumn.AllowEdit = false;
            this.gridColumn15.OptionsColumn.ReadOnly = true;
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
            this.gridColumn16.OptionsColumn.AllowEdit = false;
            this.gridColumn16.OptionsColumn.ReadOnly = true;
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
            this.gridColumn17.OptionsColumn.AllowEdit = false;
            this.gridColumn17.OptionsColumn.ReadOnly = true;
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
            this.gridColumn18.Caption = "Approved By";
            this.gridColumn18.FieldName = "APPROVEDBY";
            this.gridColumn18.Name = "gridColumn18";
            this.gridColumn18.OptionsColumn.AllowEdit = false;
            this.gridColumn18.OptionsColumn.ReadOnly = true;
            this.gridColumn18.Visible = true;
            this.gridColumn18.VisibleIndex = 8;
            // 
            // repositoryItemCheckEdit2
            // 
            this.repositoryItemCheckEdit2.AutoHeight = false;
            this.repositoryItemCheckEdit2.Name = "repositoryItemCheckEdit2";
            this.repositoryItemCheckEdit2.NullStyle = DevExpress.XtraEditors.Controls.StyleIndeterminate.Inactive;
            // 
            // TransactionReview
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(1019, 463);
            this.Controls.Add(this.xtraTabControl1);
            this.Controls.Add(this.statusStrip1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.Name = "TransactionReview";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "TransactionReview";
            this.Load += new System.EventHandler(this.TransactionReview_Load);
            ((System.ComponentModel.ISupportInitialize)(this.xtraTabControl1)).EndInit();
            this.xtraTabControl1.ResumeLayout(false);
            this.tbPayment.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.grdPayments)).EndInit();
            this.mnuPayments.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.vwPayments)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.repositoryItemCheckEdit1)).EndInit();
            this.tbReceipt.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.grdReceipts)).EndInit();
            this.mnuReceipt.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.vwReceipts)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.repositoryItemCheckEdit2)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraTab.XtraTabControl xtraTabControl1;
        private DevExpress.XtraTab.XtraTabPage tbPayment;
        private DevExpress.XtraGrid.GridControl grdPayments;
        private DevExpress.XtraGrid.Views.Grid.GridView vwPayments;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn1;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn2;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn3;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn4;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn5;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn6;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn7;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn8;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn9;
        private DevExpress.XtraEditors.Repository.RepositoryItemCheckEdit repositoryItemCheckEdit1;
        private DevExpress.XtraTab.XtraTabPage tbReceipt;
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
        private System.Windows.Forms.ContextMenuStrip mnuReceipt;
        private System.Windows.Forms.ToolStripMenuItem reprintReceiptToolStripMenuItem;
        private System.Windows.Forms.ContextMenuStrip mnuPayments;
        private System.Windows.Forms.ToolStripMenuItem reprintPaymentRequisitionToolStripMenuItem;
    }
}