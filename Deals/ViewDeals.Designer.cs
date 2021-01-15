namespace Deals
{
    partial class ViewDeals
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
            this.groupControl1 = new DevExpress.XtraEditors.GroupControl();
            this.rdoNone = new System.Windows.Forms.RadioButton();
            this.rdoBroker = new System.Windows.Forms.RadioButton();
            this.labelControl1 = new DevExpress.XtraEditors.LabelControl();
            this.dtDealDate = new DevExpress.XtraEditors.DateEdit();
            this.grdDeals = new DevExpress.XtraGrid.GridControl();
            this.mnuClientDeals = new System.Windows.Forms.ContextMenuStrip();
            this.printSelectedToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.printAllToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.vwDeals = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.gridColumn1 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn2 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn3 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn4 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn5 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn6 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn7 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn8 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn9 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn10 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn11 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn12 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn13 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn14 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.toolTip1 = new System.Windows.Forms.ToolTip();
            this.panel1 = new System.Windows.Forms.Panel();
            this.brnExcel = new DevExpress.XtraEditors.SimpleButton();
            this.simpleButton1 = new DevExpress.XtraEditors.SimpleButton();
            this.btnDayBook = new DevExpress.XtraEditors.SimpleButton();
            this.saveFileDialog1 = new System.Windows.Forms.SaveFileDialog();
            ((System.ComponentModel.ISupportInitialize)(this.groupControl1)).BeginInit();
            this.groupControl1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dtDealDate.Properties.CalendarTimeProperties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDealDate.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.grdDeals)).BeginInit();
            this.mnuClientDeals.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.vwDeals)).BeginInit();
            this.panel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Location = new System.Drawing.Point(0, 518);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(1011, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // groupControl1
            // 
            this.groupControl1.Controls.Add(this.rdoNone);
            this.groupControl1.Controls.Add(this.rdoBroker);
            this.groupControl1.Controls.Add(this.labelControl1);
            this.groupControl1.Controls.Add(this.dtDealDate);
            this.groupControl1.Location = new System.Drawing.Point(305, 5);
            this.groupControl1.LookAndFeel.SkinName = "Office 2010 Blue";
            this.groupControl1.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.Flat;
            this.groupControl1.LookAndFeel.UseDefaultLookAndFeel = false;
            this.groupControl1.Name = "groupControl1";
            this.groupControl1.Size = new System.Drawing.Size(386, 71);
            this.groupControl1.TabIndex = 1;
            this.groupControl1.Text = "Deal Options";
            // 
            // rdoNone
            // 
            this.rdoNone.AutoSize = true;
            this.rdoNone.Checked = true;
            this.rdoNone.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.rdoNone.Location = new System.Drawing.Point(140, 49);
            this.rdoNone.Name = "rdoNone";
            this.rdoNone.Size = new System.Drawing.Size(130, 18);
            this.rdoNone.TabIndex = 3;
            this.rdoNone.TabStop = true;
            this.rdoNone.Text = "Non-broker Deals";
            this.rdoNone.UseVisualStyleBackColor = true;
            this.rdoNone.Click += new System.EventHandler(this.dtDealDate_EditValueChanged);
            // 
            // rdoBroker
            // 
            this.rdoBroker.AutoSize = true;
            this.rdoBroker.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.rdoBroker.Location = new System.Drawing.Point(39, 49);
            this.rdoBroker.Name = "rdoBroker";
            this.rdoBroker.Size = new System.Drawing.Size(101, 18);
            this.rdoBroker.TabIndex = 2;
            this.rdoBroker.Text = "Broker Deals";
            this.rdoBroker.UseVisualStyleBackColor = true;
            this.rdoBroker.Click += new System.EventHandler(this.dtDealDate_EditValueChanged);
            // 
            // labelControl1
            // 
            this.labelControl1.Appearance.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.labelControl1.Location = new System.Drawing.Point(12, 26);
            this.labelControl1.Name = "labelControl1";
            this.labelControl1.Size = new System.Drawing.Size(59, 14);
            this.labelControl1.TabIndex = 1;
            this.labelControl1.Text = "Deal Date";
            // 
            // dtDealDate
            // 
            this.dtDealDate.EditValue = null;
            this.dtDealDate.Location = new System.Drawing.Point(77, 23);
            this.dtDealDate.Name = "dtDealDate";
            this.dtDealDate.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.dtDealDate.Properties.Appearance.Options.UseFont = true;
            this.dtDealDate.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtDealDate.Properties.CalendarTimeProperties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtDealDate.Properties.DisplayFormat.FormatString = "yyyy/MM/dd";
            this.dtDealDate.Properties.DisplayFormat.FormatType = DevExpress.Utils.FormatType.DateTime;
            this.dtDealDate.Properties.Mask.EditMask = "yyyy/MM/dd";
            this.dtDealDate.Size = new System.Drawing.Size(133, 20);
            this.dtDealDate.TabIndex = 0;
            this.dtDealDate.EditValueChanged += new System.EventHandler(this.dtDealDate_EditValueChanged);
            // 
            // grdDeals
            // 
            this.grdDeals.ContextMenuStrip = this.mnuClientDeals;
            this.grdDeals.Location = new System.Drawing.Point(0, 80);
            this.grdDeals.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.UltraFlat;
            this.grdDeals.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grdDeals.MainView = this.vwDeals;
            this.grdDeals.Name = "grdDeals";
            this.grdDeals.Size = new System.Drawing.Size(1011, 402);
            this.grdDeals.TabIndex = 2;
            this.toolTip1.SetToolTip(this.grdDeals, "Right-click for options");
            this.grdDeals.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.vwDeals});
            // 
            // mnuClientDeals
            // 
            this.mnuClientDeals.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.printSelectedToolStripMenuItem,
            this.printAllToolStripMenuItem});
            this.mnuClientDeals.Name = "mnuClientDeals";
            this.mnuClientDeals.Size = new System.Drawing.Size(147, 48);
            // 
            // printSelectedToolStripMenuItem
            // 
            this.printSelectedToolStripMenuItem.Name = "printSelectedToolStripMenuItem";
            this.printSelectedToolStripMenuItem.Size = new System.Drawing.Size(146, 22);
            this.printSelectedToolStripMenuItem.Text = "Print Selected";
            this.printSelectedToolStripMenuItem.Click += new System.EventHandler(this.printSelectedToolStripMenuItem_Click);
            // 
            // printAllToolStripMenuItem
            // 
            this.printAllToolStripMenuItem.Name = "printAllToolStripMenuItem";
            this.printAllToolStripMenuItem.Size = new System.Drawing.Size(146, 22);
            this.printAllToolStripMenuItem.Text = "Print All";
            this.printAllToolStripMenuItem.Click += new System.EventHandler(this.printAllToolStripMenuItem_Click);
            // 
            // vwDeals
            // 
            this.vwDeals.Appearance.GroupPanel.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.vwDeals.Appearance.GroupPanel.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.vwDeals.Appearance.GroupPanel.Options.UseFont = true;
            this.vwDeals.Appearance.GroupPanel.Options.UseForeColor = true;
            this.vwDeals.Columns.AddRange(new DevExpress.XtraGrid.Columns.GridColumn[] {
            this.gridColumn1,
            this.gridColumn2,
            this.gridColumn3,
            this.gridColumn4,
            this.gridColumn5,
            this.gridColumn6,
            this.gridColumn7,
            this.gridColumn8,
            this.gridColumn9,
            this.gridColumn10,
            this.gridColumn11,
            this.gridColumn12,
            this.gridColumn13,
            this.gridColumn14});
            this.vwDeals.GridControl = this.grdDeals;
            this.vwDeals.GroupPanelText = "Client Deals";
            this.vwDeals.HorzScrollVisibility = DevExpress.XtraGrid.Views.Base.ScrollVisibility.Always;
            this.vwDeals.Name = "vwDeals";
            this.vwDeals.OptionsSelection.MultiSelect = true;
            this.vwDeals.OptionsView.ColumnAutoWidth = false;
            // 
            // gridColumn1
            // 
            this.gridColumn1.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn1.AppearanceHeader.Options.UseFont = true;
            this.gridColumn1.Caption = "Deal #";
            this.gridColumn1.FieldName = "dealno";
            this.gridColumn1.Name = "gridColumn1";
            this.gridColumn1.OptionsColumn.AllowEdit = false;
            this.gridColumn1.OptionsColumn.ReadOnly = true;
            this.gridColumn1.Visible = true;
            this.gridColumn1.VisibleIndex = 0;
            this.gridColumn1.Width = 39;
            // 
            // gridColumn2
            // 
            this.gridColumn2.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn2.AppearanceHeader.Options.UseFont = true;
            this.gridColumn2.Caption = "Counter";
            this.gridColumn2.FieldName = "asset";
            this.gridColumn2.Name = "gridColumn2";
            this.gridColumn2.OptionsColumn.AllowEdit = false;
            this.gridColumn2.OptionsColumn.ReadOnly = true;
            this.gridColumn2.Visible = true;
            this.gridColumn2.VisibleIndex = 1;
            this.gridColumn2.Width = 64;
            // 
            // gridColumn3
            // 
            this.gridColumn3.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn3.AppearanceHeader.Options.UseFont = true;
            this.gridColumn3.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn3.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn3.Caption = "Quantity";
            this.gridColumn3.FieldName = "qty";
            this.gridColumn3.Name = "gridColumn3";
            this.gridColumn3.OptionsColumn.AllowEdit = false;
            this.gridColumn3.OptionsColumn.ReadOnly = true;
            this.gridColumn3.Visible = true;
            this.gridColumn3.VisibleIndex = 2;
            this.gridColumn3.Width = 63;
            // 
            // gridColumn4
            // 
            this.gridColumn4.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn4.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn4.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn4.AppearanceHeader.Options.UseFont = true;
            this.gridColumn4.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn4.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn4.Caption = "Price";
            this.gridColumn4.DisplayFormat.FormatString = "0.00";
            this.gridColumn4.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn4.FieldName = "price";
            this.gridColumn4.Name = "gridColumn4";
            this.gridColumn4.OptionsColumn.AllowEdit = false;
            this.gridColumn4.OptionsColumn.ReadOnly = true;
            this.gridColumn4.Visible = true;
            this.gridColumn4.VisibleIndex = 3;
            this.gridColumn4.Width = 42;
            // 
            // gridColumn5
            // 
            this.gridColumn5.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn5.AppearanceHeader.Options.UseFont = true;
            this.gridColumn5.Caption = "Client";
            this.gridColumn5.FieldName = "client";
            this.gridColumn5.Name = "gridColumn5";
            this.gridColumn5.OptionsColumn.AllowEdit = false;
            this.gridColumn5.OptionsColumn.ReadOnly = true;
            this.gridColumn5.Visible = true;
            this.gridColumn5.VisibleIndex = 4;
            this.gridColumn5.Width = 191;
            // 
            // gridColumn6
            // 
            this.gridColumn6.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn6.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn6.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn6.AppearanceHeader.Options.UseFont = true;
            this.gridColumn6.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn6.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn6.Caption = "Consideration";
            this.gridColumn6.DisplayFormat.FormatString = "#,##0.00";
            this.gridColumn6.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn6.FieldName = "consideration";
            this.gridColumn6.Name = "gridColumn6";
            this.gridColumn6.OptionsColumn.AllowEdit = false;
            this.gridColumn6.OptionsColumn.ReadOnly = true;
            this.gridColumn6.Visible = true;
            this.gridColumn6.VisibleIndex = 5;
            this.gridColumn6.Width = 88;
            // 
            // gridColumn7
            // 
            this.gridColumn7.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn7.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn7.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn7.AppearanceHeader.Options.UseFont = true;
            this.gridColumn7.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn7.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn7.Caption = "Commission";
            this.gridColumn7.DisplayFormat.FormatString = "{0:n2}";
            this.gridColumn7.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn7.FieldName = "grosscommission";
            this.gridColumn7.Name = "gridColumn7";
            this.gridColumn7.OptionsColumn.AllowEdit = false;
            this.gridColumn7.OptionsColumn.ReadOnly = true;
            this.gridColumn7.Visible = true;
            this.gridColumn7.VisibleIndex = 6;
            this.gridColumn7.Width = 79;
            // 
            // gridColumn8
            // 
            this.gridColumn8.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn8.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn8.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn8.AppearanceHeader.Options.UseFont = true;
            this.gridColumn8.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn8.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn8.Caption = "Stamp Duty";
            this.gridColumn8.DisplayFormat.FormatString = "#,##0.00";
            this.gridColumn8.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn8.FieldName = "stampduty";
            this.gridColumn8.Name = "gridColumn8";
            this.gridColumn8.OptionsColumn.AllowEdit = false;
            this.gridColumn8.OptionsColumn.ReadOnly = true;
            this.gridColumn8.Visible = true;
            this.gridColumn8.VisibleIndex = 7;
            this.gridColumn8.Width = 66;
            // 
            // gridColumn9
            // 
            this.gridColumn9.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn9.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn9.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn9.AppearanceHeader.Options.UseFont = true;
            this.gridColumn9.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn9.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn9.Caption = "Capital Gains";
            this.gridColumn9.DisplayFormat.FormatString = "#,##0.00";
            this.gridColumn9.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn9.FieldName = "capitalgains";
            this.gridColumn9.Name = "gridColumn9";
            this.gridColumn9.OptionsColumn.AllowEdit = false;
            this.gridColumn9.OptionsColumn.ReadOnly = true;
            this.gridColumn9.Visible = true;
            this.gridColumn9.VisibleIndex = 8;
            this.gridColumn9.Width = 68;
            // 
            // gridColumn10
            // 
            this.gridColumn10.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn10.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn10.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn10.AppearanceHeader.Options.UseFont = true;
            this.gridColumn10.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn10.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn10.Caption = "Inv. Protection";
            this.gridColumn10.DisplayFormat.FormatString = "#,##0.00";
            this.gridColumn10.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn10.FieldName = "investorprotection";
            this.gridColumn10.Name = "gridColumn10";
            this.gridColumn10.OptionsColumn.AllowEdit = false;
            this.gridColumn10.OptionsColumn.ReadOnly = true;
            this.gridColumn10.Visible = true;
            this.gridColumn10.VisibleIndex = 9;
            this.gridColumn10.Width = 68;
            // 
            // gridColumn11
            // 
            this.gridColumn11.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn11.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn11.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn11.AppearanceHeader.Options.UseFont = true;
            this.gridColumn11.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn11.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn11.Caption = "ZSE Levy";
            this.gridColumn11.DisplayFormat.FormatString = "#,##0.00";
            this.gridColumn11.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn11.FieldName = "zselevy";
            this.gridColumn11.Name = "gridColumn11";
            this.gridColumn11.OptionsColumn.AllowEdit = false;
            this.gridColumn11.OptionsColumn.ReadOnly = true;
            this.gridColumn11.Visible = true;
            this.gridColumn11.VisibleIndex = 10;
            this.gridColumn11.Width = 68;
            // 
            // gridColumn12
            // 
            this.gridColumn12.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn12.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn12.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn12.AppearanceHeader.Options.UseFont = true;
            this.gridColumn12.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn12.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn12.Caption = "Comm. Levy";
            this.gridColumn12.DisplayFormat.FormatString = "#,##0.00";
            this.gridColumn12.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn12.FieldName = "commissionerlevy";
            this.gridColumn12.Name = "gridColumn12";
            this.gridColumn12.OptionsColumn.AllowEdit = false;
            this.gridColumn12.OptionsColumn.ReadOnly = true;
            this.gridColumn12.Visible = true;
            this.gridColumn12.VisibleIndex = 11;
            this.gridColumn12.Width = 78;
            // 
            // gridColumn13
            // 
            this.gridColumn13.AppearanceCell.Options.UseTextOptions = true;
            this.gridColumn13.AppearanceCell.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn13.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn13.AppearanceHeader.Options.UseFont = true;
            this.gridColumn13.AppearanceHeader.Options.UseTextOptions = true;
            this.gridColumn13.AppearanceHeader.TextOptions.HAlignment = DevExpress.Utils.HorzAlignment.Far;
            this.gridColumn13.Caption = "CSD Levy";
            this.gridColumn13.DisplayFormat.FormatString = "#,##0.00";
            this.gridColumn13.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn13.FieldName = "csdlevy";
            this.gridColumn13.Name = "gridColumn13";
            this.gridColumn13.OptionsColumn.AllowEdit = false;
            this.gridColumn13.OptionsColumn.ReadOnly = true;
            this.gridColumn13.Visible = true;
            this.gridColumn13.VisibleIndex = 12;
            this.gridColumn13.Width = 86;
            // 
            // gridColumn14
            // 
            this.gridColumn14.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn14.AppearanceHeader.Options.UseFont = true;
            this.gridColumn14.Caption = "VAT";
            this.gridColumn14.DisplayFormat.FormatString = "#,##0.00";
            this.gridColumn14.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            this.gridColumn14.FieldName = "VAT";
            this.gridColumn14.Name = "gridColumn14";
            this.gridColumn14.OptionsColumn.AllowEdit = false;
            this.gridColumn14.OptionsColumn.ReadOnly = true;
            this.gridColumn14.Visible = true;
            this.gridColumn14.VisibleIndex = 13;
            // 
            // toolTip1
            // 
            this.toolTip1.ToolTipTitle = "Right-click for options";
            // 
            // panel1
            // 
            this.panel1.Controls.Add(this.brnExcel);
            this.panel1.Controls.Add(this.simpleButton1);
            this.panel1.Controls.Add(this.btnDayBook);
            this.panel1.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.panel1.Location = new System.Drawing.Point(0, 482);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(1011, 36);
            this.panel1.TabIndex = 5;
            // 
            // brnExcel
            // 
            this.brnExcel.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.brnExcel.Location = new System.Drawing.Point(111, 7);
            this.brnExcel.Name = "brnExcel";
            this.brnExcel.Size = new System.Drawing.Size(121, 23);
            this.brnExcel.TabIndex = 6;
            this.brnExcel.Text = "View Excel Daybook";
            this.brnExcel.Click += new System.EventHandler(this.btnDayBook_Click);
            // 
            // simpleButton1
            // 
            this.simpleButton1.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.simpleButton1.Location = new System.Drawing.Point(904, 6);
            this.simpleButton1.Name = "simpleButton1";
            this.simpleButton1.Size = new System.Drawing.Size(94, 23);
            this.simpleButton1.TabIndex = 5;
            this.simpleButton1.Text = "Close";
            this.simpleButton1.Click += new System.EventHandler(this.simpleButton1_Click);
            // 
            // btnDayBook
            // 
            this.btnDayBook.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnDayBook.Location = new System.Drawing.Point(11, 6);
            this.btnDayBook.Name = "btnDayBook";
            this.btnDayBook.Size = new System.Drawing.Size(94, 23);
            this.btnDayBook.TabIndex = 4;
            this.btnDayBook.Text = "Print Daybook";
            this.btnDayBook.Click += new System.EventHandler(this.btnDayBook_Click);
            // 
            // ViewDeals
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(1011, 540);
            this.Controls.Add(this.panel1);
            this.Controls.Add(this.grdDeals);
            this.Controls.Add(this.groupControl1);
            this.Controls.Add(this.statusStrip1);
            this.Name = "ViewDeals";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "View Deals";
            this.Load += new System.EventHandler(this.ViewDeals_Load);
            ((System.ComponentModel.ISupportInitialize)(this.groupControl1)).EndInit();
            this.groupControl1.ResumeLayout(false);
            this.groupControl1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dtDealDate.Properties.CalendarTimeProperties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDealDate.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.grdDeals)).EndInit();
            this.mnuClientDeals.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.vwDeals)).EndInit();
            this.panel1.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraEditors.GroupControl groupControl1;
        private System.Windows.Forms.RadioButton rdoNone;
        private System.Windows.Forms.RadioButton rdoBroker;
        private DevExpress.XtraEditors.LabelControl labelControl1;
        private DevExpress.XtraEditors.DateEdit dtDealDate;
        private DevExpress.XtraGrid.GridControl grdDeals;
        private DevExpress.XtraGrid.Views.Grid.GridView vwDeals;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn1;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn2;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn3;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn4;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn5;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn6;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn7;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn8;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn9;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn10;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn11;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn12;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn13;
        private System.Windows.Forms.ContextMenuStrip mnuClientDeals;
        private System.Windows.Forms.ToolStripMenuItem printSelectedToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem printAllToolStripMenuItem;
        private System.Windows.Forms.ToolTip toolTip1;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn14;
        private System.Windows.Forms.Panel panel1;
        private DevExpress.XtraEditors.SimpleButton simpleButton1;
        private DevExpress.XtraEditors.SimpleButton btnDayBook;
        private DevExpress.XtraEditors.SimpleButton brnExcel;
        private System.Windows.Forms.SaveFileDialog saveFileDialog1;
    }
}