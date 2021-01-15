namespace Clients
{
    partial class ClientListing
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
            this.grdClients = new DevExpress.XtraGrid.GridControl();
            this.vwClients = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.gridColumn1 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn2 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn3 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn4 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.gridColumn5 = new DevExpress.XtraGrid.Columns.GridColumn();
            this.grpClient = new DevExpress.XtraEditors.GroupControl();
            this.lblType = new DevExpress.XtraEditors.LabelControl();
            this.labelControl3 = new DevExpress.XtraEditors.LabelControl();
            this.lblName = new DevExpress.XtraEditors.LabelControl();
            this.labelControl2 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl1 = new DevExpress.XtraEditors.LabelControl();
            this.txtClient = new DevExpress.XtraEditors.TextEdit();
            this.lblAddress = new DevExpress.XtraEditors.LabelControl();
            this.labelControl5 = new DevExpress.XtraEditors.LabelControl();
            this.lblPhone = new DevExpress.XtraEditors.LabelControl();
            this.Phone = new DevExpress.XtraEditors.LabelControl();
            ((System.ComponentModel.ISupportInitialize)(this.grdClients)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.vwClients)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.grpClient)).BeginInit();
            this.grpClient.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.txtClient.Properties)).BeginInit();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Location = new System.Drawing.Point(0, 431);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(919, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // grdClients
            // 
            this.grdClients.Font = new System.Drawing.Font("Times New Roman", 9F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.grdClients.Location = new System.Drawing.Point(0, 89);
            this.grdClients.LookAndFeel.SkinName = "Office 2016 Colorful";
            this.grdClients.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grdClients.MainView = this.vwClients;
            this.grdClients.Name = "grdClients";
            this.grdClients.Size = new System.Drawing.Size(552, 339);
            this.grdClients.TabIndex = 1;
            this.grdClients.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.vwClients});
            // 
            // vwClients
            // 
            this.vwClients.Columns.AddRange(new DevExpress.XtraGrid.Columns.GridColumn[] {
            this.gridColumn1,
            this.gridColumn2,
            this.gridColumn3,
            this.gridColumn4,
            this.gridColumn5});
            this.vwClients.GridControl = this.grdClients;
            this.vwClients.GroupPanelText = "Client Listing";
            this.vwClients.Name = "vwClients";
            this.vwClients.SelectionChanged += new DevExpress.Data.SelectionChangedEventHandler(this.vwClients_SelectionChanged);
            this.vwClients.FocusedRowChanged += new DevExpress.XtraGrid.Views.Base.FocusedRowChangedEventHandler(this.vwClients_FocusedRowChanged);
            this.vwClients.DoubleClick += new System.EventHandler(this.vwClients_DoubleClick);
            // 
            // gridColumn1
            // 
            this.gridColumn1.AppearanceCell.Font = new System.Drawing.Font("Arial", 9F);
            this.gridColumn1.AppearanceCell.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.gridColumn1.AppearanceCell.Options.UseFont = true;
            this.gridColumn1.AppearanceCell.Options.UseForeColor = true;
            this.gridColumn1.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.gridColumn1.AppearanceHeader.Options.UseFont = true;
            this.gridColumn1.Caption = "Client #";
            this.gridColumn1.FieldName = "clientno";
            this.gridColumn1.Name = "gridColumn1";
            this.gridColumn1.OptionsColumn.AllowEdit = false;
            this.gridColumn1.OptionsColumn.ReadOnly = true;
            this.gridColumn1.Visible = true;
            this.gridColumn1.VisibleIndex = 0;
            this.gridColumn1.Width = 79;
            // 
            // gridColumn2
            // 
            this.gridColumn2.AppearanceCell.Font = new System.Drawing.Font("Arial", 9F);
            this.gridColumn2.AppearanceCell.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.gridColumn2.AppearanceCell.Options.UseFont = true;
            this.gridColumn2.AppearanceCell.Options.UseForeColor = true;
            this.gridColumn2.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.gridColumn2.AppearanceHeader.Options.UseFont = true;
            this.gridColumn2.Caption = "Client Name";
            this.gridColumn2.FieldName = "clientname";
            this.gridColumn2.Name = "gridColumn2";
            this.gridColumn2.OptionsColumn.AllowEdit = false;
            this.gridColumn2.OptionsColumn.ReadOnly = true;
            this.gridColumn2.Visible = true;
            this.gridColumn2.VisibleIndex = 1;
            this.gridColumn2.Width = 276;
            // 
            // gridColumn3
            // 
            this.gridColumn3.AppearanceCell.Font = new System.Drawing.Font("Arial", 9F);
            this.gridColumn3.AppearanceCell.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.gridColumn3.AppearanceCell.Options.UseFont = true;
            this.gridColumn3.AppearanceCell.Options.UseForeColor = true;
            this.gridColumn3.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.gridColumn3.AppearanceHeader.Options.UseFont = true;
            this.gridColumn3.Caption = "Type";
            this.gridColumn3.FieldName = "clienttype";
            this.gridColumn3.Name = "gridColumn3";
            this.gridColumn3.OptionsColumn.AllowEdit = false;
            this.gridColumn3.OptionsColumn.ReadOnly = true;
            this.gridColumn3.Visible = true;
            this.gridColumn3.VisibleIndex = 2;
            this.gridColumn3.Width = 160;
            // 
            // gridColumn4
            // 
            this.gridColumn4.AppearanceCell.Font = new System.Drawing.Font("Tahoma", 9F);
            this.gridColumn4.AppearanceCell.Options.UseFont = true;
            this.gridColumn4.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.gridColumn4.AppearanceHeader.Options.UseFont = true;
            this.gridColumn4.Caption = "gridColumn4";
            this.gridColumn4.FieldName = "category";
            this.gridColumn4.Name = "gridColumn4";
            this.gridColumn4.OptionsColumn.AllowEdit = false;
            this.gridColumn4.OptionsColumn.ReadOnly = true;
            this.gridColumn4.Width = 27;
            // 
            // gridColumn5
            // 
            this.gridColumn5.AppearanceCell.Font = new System.Drawing.Font("Tahoma", 9F);
            this.gridColumn5.AppearanceCell.Options.UseFont = true;
            this.gridColumn5.AppearanceHeader.Font = new System.Drawing.Font("Tahoma", 9F, System.Drawing.FontStyle.Bold);
            this.gridColumn5.AppearanceHeader.Options.UseFont = true;
            this.gridColumn5.Caption = "gridColumn5";
            this.gridColumn5.Name = "gridColumn5";
            this.gridColumn5.OptionsColumn.AllowEdit = false;
            this.gridColumn5.OptionsColumn.ReadOnly = true;
            this.gridColumn5.Width = 28;
            // 
            // grpClient
            // 
            this.grpClient.Appearance.BackColor = System.Drawing.Color.White;
            this.grpClient.Appearance.Options.UseBackColor = true;
            this.grpClient.Controls.Add(this.lblPhone);
            this.grpClient.Controls.Add(this.Phone);
            this.grpClient.Controls.Add(this.lblAddress);
            this.grpClient.Controls.Add(this.labelControl5);
            this.grpClient.Controls.Add(this.lblType);
            this.grpClient.Controls.Add(this.labelControl3);
            this.grpClient.Controls.Add(this.lblName);
            this.grpClient.Controls.Add(this.labelControl2);
            this.grpClient.Location = new System.Drawing.Point(558, 89);
            this.grpClient.LookAndFeel.SkinName = "Office 2013";
            this.grpClient.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grpClient.Name = "grpClient";
            this.grpClient.Size = new System.Drawing.Size(349, 223);
            this.grpClient.TabIndex = 2;
            this.grpClient.Text = "Selected Client";
            // 
            // lblType
            // 
            this.lblType.Appearance.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.lblType.Location = new System.Drawing.Point(68, 76);
            this.lblType.Name = "lblType";
            this.lblType.Size = new System.Drawing.Size(32, 13);
            this.lblType.TabIndex = 3;
            this.lblType.Text = "Name";
            // 
            // labelControl3
            // 
            this.labelControl3.Location = new System.Drawing.Point(17, 76);
            this.labelControl3.Name = "labelControl3";
            this.labelControl3.Size = new System.Drawing.Size(45, 13);
            this.labelControl3.TabIndex = 2;
            this.labelControl3.Text = "Category";
            // 
            // lblName
            // 
            this.lblName.Appearance.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.lblName.Appearance.TextOptions.WordWrap = DevExpress.Utils.WordWrap.Wrap;
            this.lblName.Location = new System.Drawing.Point(68, 41);
            this.lblName.Name = "lblName";
            this.lblName.Size = new System.Drawing.Size(32, 13);
            this.lblName.TabIndex = 1;
            this.lblName.Text = "Name";
            // 
            // labelControl2
            // 
            this.labelControl2.Location = new System.Drawing.Point(17, 41);
            this.labelControl2.Name = "labelControl2";
            this.labelControl2.Size = new System.Drawing.Size(27, 13);
            this.labelControl2.TabIndex = 0;
            this.labelControl2.Text = "Name";
            // 
            // labelControl1
            // 
            this.labelControl1.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.labelControl1.Location = new System.Drawing.Point(21, 49);
            this.labelControl1.Name = "labelControl1";
            this.labelControl1.Size = new System.Drawing.Size(75, 16);
            this.labelControl1.TabIndex = 3;
            this.labelControl1.Text = "Client Name";
            // 
            // txtClient
            // 
            this.txtClient.Location = new System.Drawing.Point(106, 48);
            this.txtClient.Name = "txtClient";
            this.txtClient.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.txtClient.Properties.Appearance.Options.UseFont = true;
            this.txtClient.Size = new System.Drawing.Size(482, 22);
            this.txtClient.TabIndex = 4;
            this.txtClient.KeyUp += new System.Windows.Forms.KeyEventHandler(this.txtClient_KeyUp);
            // 
            // lblAddress
            // 
            this.lblAddress.Appearance.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.lblAddress.Location = new System.Drawing.Point(68, 106);
            this.lblAddress.Name = "lblAddress";
            this.lblAddress.Size = new System.Drawing.Size(32, 13);
            this.lblAddress.TabIndex = 5;
            this.lblAddress.Text = "Name";
            // 
            // labelControl5
            // 
            this.labelControl5.Location = new System.Drawing.Point(17, 106);
            this.labelControl5.Name = "labelControl5";
            this.labelControl5.Size = new System.Drawing.Size(39, 13);
            this.labelControl5.TabIndex = 4;
            this.labelControl5.Text = "Address";
            // 
            // lblPhone
            // 
            this.lblPhone.Appearance.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.lblPhone.Location = new System.Drawing.Point(68, 172);
            this.lblPhone.Name = "lblPhone";
            this.lblPhone.Size = new System.Drawing.Size(32, 13);
            this.lblPhone.TabIndex = 7;
            this.lblPhone.Text = "Name";
            // 
            // Phone
            // 
            this.Phone.Location = new System.Drawing.Point(17, 172);
            this.Phone.Name = "Phone";
            this.Phone.Size = new System.Drawing.Size(30, 13);
            this.Phone.TabIndex = 6;
            this.Phone.Text = "Phone";
            // 
            // ClientListing
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(919, 453);
            this.Controls.Add(this.txtClient);
            this.Controls.Add(this.labelControl1);
            this.Controls.Add(this.grpClient);
            this.Controls.Add(this.grdClients);
            this.Controls.Add(this.statusStrip1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.Name = "ClientListing";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Client Listing";
            this.Load += new System.EventHandler(this.ClientListing_Load);
            ((System.ComponentModel.ISupportInitialize)(this.grdClients)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.vwClients)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.grpClient)).EndInit();
            this.grpClient.ResumeLayout(false);
            this.grpClient.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.txtClient.Properties)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraGrid.GridControl grdClients;
        private DevExpress.XtraGrid.Views.Grid.GridView vwClients;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn1;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn2;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn3;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn4;
        private DevExpress.XtraGrid.Columns.GridColumn gridColumn5;
        private DevExpress.XtraEditors.GroupControl grpClient;
        private DevExpress.XtraEditors.LabelControl labelControl1;
        private DevExpress.XtraEditors.TextEdit txtClient;
        private DevExpress.XtraEditors.LabelControl lblType;
        private DevExpress.XtraEditors.LabelControl labelControl3;
        private DevExpress.XtraEditors.LabelControl lblName;
        private DevExpress.XtraEditors.LabelControl labelControl2;
        private DevExpress.XtraEditors.LabelControl lblAddress;
        private DevExpress.XtraEditors.LabelControl labelControl5;
        private DevExpress.XtraEditors.LabelControl lblPhone;
        private DevExpress.XtraEditors.LabelControl Phone;
    }
}