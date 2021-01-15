namespace Deals
{
    partial class NewBrokerDeal
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
            this.grdCounterparty = new DevExpress.XtraGrid.GridControl();
            this.vwCounterparty = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.gridColumn1 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn2 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.dtDealDate = new DevExpress.XtraEditors.DateEdit();
            this.cmbAsset = new DevExpress.XtraEditors.ComboBoxEdit();
            this.txtQty = new DevExpress.XtraEditors.TextEdit();
            this.txtPrice = new DevExpress.XtraEditors.TextEdit();
            this.labelControl3 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl4 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl5 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl6 = new DevExpress.XtraEditors.LabelControl();
            this.groupControl1 = new DevExpress.XtraEditors.GroupControl();
            this.rdoSell = new System.Windows.Forms.RadioButton();
            this.rdoBuy = new System.Windows.Forms.RadioButton();
            this.btnSave = new DevExpress.XtraEditors.SimpleButton();
            this.btnClose = new DevExpress.XtraEditors.SimpleButton();
            ((System.ComponentModel.ISupportInitialize)(this.grdCounterparty)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.vwCounterparty)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDealDate.Properties.CalendarTimeProperties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDealDate.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbAsset.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtQty.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtPrice.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.groupControl1)).BeginInit();
            this.groupControl1.SuspendLayout();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Location = new System.Drawing.Point(0, 295);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(656, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // grdCounterparty
            // 
            this.grdCounterparty.AccessibleRole = System.Windows.Forms.AccessibleRole.Client;
            this.grdCounterparty.Dock = System.Windows.Forms.DockStyle.Left;
            this.grdCounterparty.Location = new System.Drawing.Point(0, 0);
            this.grdCounterparty.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.UltraFlat;
            this.grdCounterparty.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grdCounterparty.MainView = this.vwCounterparty;
            this.grdCounterparty.Name = "grdCounterparty";
            this.grdCounterparty.Size = new System.Drawing.Size(287, 295);
            this.grdCounterparty.TabIndex = 1;
            this.grdCounterparty.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.vwCounterparty});
            // 
            // vwCounterparty
            // 
            this.vwCounterparty.Appearance.GroupPanel.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.vwCounterparty.Appearance.GroupPanel.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.vwCounterparty.Appearance.GroupPanel.Options.UseFont = true;
            this.vwCounterparty.Appearance.GroupPanel.Options.UseForeColor = true;
            this.vwCounterparty.Columns.AddRange(new DevExpress.XtraGrid.Columns.GridColumn[] {
            this.gridColumn1,
            this.gridColumn2});
            this.vwCounterparty.GridControl = this.grdCounterparty;
            this.vwCounterparty.GroupPanelText = "Counterparty";
            this.vwCounterparty.Name = "vwCounterparty";
            // 
            // gridColumn1
            // 
            this.gridColumn1.Caption = "gridColumn1";
            this.gridColumn1.FieldName = "clientno";
            this.gridColumn1.Name = "gridColumn1";
            // 
            // gridColumn2
            // 
            this.gridColumn2.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.gridColumn2.AppearanceHeader.Options.UseFont = true;
            this.gridColumn2.Caption = "Broker Name";
            this.gridColumn2.FieldName = "companyname";
            this.gridColumn2.Name = "gridColumn2";
            this.gridColumn2.OptionsColumn.AllowEdit = false;
            this.gridColumn2.OptionsColumn.ReadOnly = true;
            this.gridColumn2.Visible = true;
            this.gridColumn2.VisibleIndex = 0;
            // 
            // dtDealDate
            // 
            this.dtDealDate.EditValue = null;
            this.dtDealDate.Location = new System.Drawing.Point(394, 107);
            this.dtDealDate.Name = "dtDealDate";
            this.dtDealDate.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.dtDealDate.Properties.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.dtDealDate.Properties.Appearance.Options.UseFont = true;
            this.dtDealDate.Properties.Appearance.Options.UseForeColor = true;
            this.dtDealDate.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtDealDate.Properties.CalendarTimeProperties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtDealDate.Size = new System.Drawing.Size(155, 22);
            this.dtDealDate.TabIndex = 2;
            // 
            // cmbAsset
            // 
            this.cmbAsset.Location = new System.Drawing.Point(394, 141);
            this.cmbAsset.Name = "cmbAsset";
            this.cmbAsset.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.cmbAsset.Properties.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.cmbAsset.Properties.Appearance.Options.UseFont = true;
            this.cmbAsset.Properties.Appearance.Options.UseForeColor = true;
            this.cmbAsset.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.cmbAsset.Size = new System.Drawing.Size(155, 22);
            this.cmbAsset.TabIndex = 3;
            // 
            // txtQty
            // 
            this.txtQty.Location = new System.Drawing.Point(394, 175);
            this.txtQty.Name = "txtQty";
            this.txtQty.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.txtQty.Properties.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.txtQty.Properties.Appearance.Options.UseFont = true;
            this.txtQty.Properties.Appearance.Options.UseForeColor = true;
            this.txtQty.Size = new System.Drawing.Size(155, 22);
            this.txtQty.TabIndex = 4;
            // 
            // txtPrice
            // 
            this.txtPrice.Location = new System.Drawing.Point(394, 209);
            this.txtPrice.Name = "txtPrice";
            this.txtPrice.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.txtPrice.Properties.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.txtPrice.Properties.Appearance.Options.UseFont = true;
            this.txtPrice.Properties.Appearance.Options.UseForeColor = true;
            this.txtPrice.Size = new System.Drawing.Size(155, 22);
            this.txtPrice.TabIndex = 5;
            // 
            // labelControl3
            // 
            this.labelControl3.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.labelControl3.Location = new System.Drawing.Point(325, 110);
            this.labelControl3.Name = "labelControl3";
            this.labelControl3.Size = new System.Drawing.Size(63, 16);
            this.labelControl3.TabIndex = 8;
            this.labelControl3.Text = "Deal Date";
            // 
            // labelControl4
            // 
            this.labelControl4.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.labelControl4.Location = new System.Drawing.Point(324, 145);
            this.labelControl4.Name = "labelControl4";
            this.labelControl4.Size = new System.Drawing.Size(38, 16);
            this.labelControl4.TabIndex = 9;
            this.labelControl4.Text = "Asset";
            // 
            // labelControl5
            // 
            this.labelControl5.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.labelControl5.Location = new System.Drawing.Point(325, 181);
            this.labelControl5.Name = "labelControl5";
            this.labelControl5.Size = new System.Drawing.Size(56, 16);
            this.labelControl5.TabIndex = 10;
            this.labelControl5.Text = "Quantity";
            // 
            // labelControl6
            // 
            this.labelControl6.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.labelControl6.Location = new System.Drawing.Point(330, 215);
            this.labelControl6.Name = "labelControl6";
            this.labelControl6.Size = new System.Drawing.Size(32, 16);
            this.labelControl6.TabIndex = 11;
            this.labelControl6.Text = "Price";
            // 
            // groupControl1
            // 
            this.groupControl1.Controls.Add(this.rdoSell);
            this.groupControl1.Controls.Add(this.rdoBuy);
            this.groupControl1.Location = new System.Drawing.Point(313, 12);
            this.groupControl1.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.UltraFlat;
            this.groupControl1.LookAndFeel.UseDefaultLookAndFeel = false;
            this.groupControl1.Name = "groupControl1";
            this.groupControl1.Size = new System.Drawing.Size(282, 74);
            this.groupControl1.TabIndex = 13;
            this.groupControl1.Text = "Deal Type";
            // 
            // rdoSell
            // 
            this.rdoSell.AutoSize = true;
            this.rdoSell.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.rdoSell.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(0)))), ((int)(((byte)(0)))));
            this.rdoSell.Location = new System.Drawing.Point(120, 30);
            this.rdoSell.Name = "rdoSell";
            this.rdoSell.Size = new System.Drawing.Size(50, 17);
            this.rdoSell.TabIndex = 1;
            this.rdoSell.TabStop = true;
            this.rdoSell.Text = "SELL";
            this.rdoSell.UseVisualStyleBackColor = true;
            // 
            // rdoBuy
            // 
            this.rdoBuy.AutoSize = true;
            this.rdoBuy.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.rdoBuy.Location = new System.Drawing.Point(17, 30);
            this.rdoBuy.Name = "rdoBuy";
            this.rdoBuy.Size = new System.Drawing.Size(47, 17);
            this.rdoBuy.TabIndex = 0;
            this.rdoBuy.TabStop = true;
            this.rdoBuy.Text = "BUY";
            this.rdoBuy.UseVisualStyleBackColor = true;
            // 
            // btnSave
            // 
            this.btnSave.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnSave.Location = new System.Drawing.Point(555, 260);
            this.btnSave.Name = "btnSave";
            this.btnSave.Size = new System.Drawing.Size(75, 23);
            this.btnSave.TabIndex = 14;
            this.btnSave.Text = "Save";
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);
            // 
            // btnClose
            // 
            this.btnClose.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnClose.Location = new System.Drawing.Point(474, 260);
            this.btnClose.Name = "btnClose";
            this.btnClose.Size = new System.Drawing.Size(75, 23);
            this.btnClose.TabIndex = 15;
            this.btnClose.Text = "Close";
            this.btnClose.Click += new System.EventHandler(this.btnClose_Click);
            // 
            // NewBrokerDeal
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(656, 317);
            this.Controls.Add(this.btnClose);
            this.Controls.Add(this.btnSave);
            this.Controls.Add(this.groupControl1);
            this.Controls.Add(this.labelControl6);
            this.Controls.Add(this.labelControl5);
            this.Controls.Add(this.labelControl4);
            this.Controls.Add(this.labelControl3);
            this.Controls.Add(this.txtPrice);
            this.Controls.Add(this.txtQty);
            this.Controls.Add(this.cmbAsset);
            this.Controls.Add(this.dtDealDate);
            this.Controls.Add(this.grdCounterparty);
            this.Controls.Add(this.statusStrip1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "NewBrokerDeal";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Broker Deal";
            this.Load += new System.EventHandler(this.NewBrokerDeal_Load);
            ((System.ComponentModel.ISupportInitialize)(this.grdCounterparty)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.vwCounterparty)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDealDate.Properties.CalendarTimeProperties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDealDate.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbAsset.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtQty.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtPrice.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.groupControl1)).EndInit();
            this.groupControl1.ResumeLayout(false);
            this.groupControl1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraGrid.GridControl grdCounterparty;
        private DevExpress.XtraGrid.Views.Grid.GridView vwCounterparty;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn1;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn2;
        private DevExpress.XtraEditors.DateEdit dtDealDate;
        private DevExpress.XtraEditors.ComboBoxEdit cmbAsset;
        private DevExpress.XtraEditors.TextEdit txtQty;
        private DevExpress.XtraEditors.TextEdit txtPrice;
        private DevExpress.XtraEditors.LabelControl labelControl3;
        private DevExpress.XtraEditors.LabelControl labelControl4;
        private DevExpress.XtraEditors.LabelControl labelControl5;
        private DevExpress.XtraEditors.LabelControl labelControl6;
        private DevExpress.XtraEditors.GroupControl groupControl1;
        private System.Windows.Forms.RadioButton rdoSell;
        private System.Windows.Forms.RadioButton rdoBuy;
        private DevExpress.XtraEditors.SimpleButton btnSave;
        private DevExpress.XtraEditors.SimpleButton btnClose;
    }
}