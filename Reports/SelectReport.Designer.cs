namespace Reports
{
    partial class SelectReport
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
            this.tbLedgers = new DevExpress.XtraTab.XtraTabPage();
            this.labelControl3 = new DevExpress.XtraEditors.LabelControl();
            this.dtEnd = new DevExpress.XtraEditors.DateEdit();
            this.cmbLedger = new DevExpress.XtraEditors.ComboBoxEdit();
            this.btnViewLedger = new DevExpress.XtraEditors.SimpleButton();
            this.btnClose = new DevExpress.XtraEditors.SimpleButton();
            this.dtStart = new DevExpress.XtraEditors.DateEdit();
            this.labelControl2 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl1 = new DevExpress.XtraEditors.LabelControl();
            this.chkAll = new DevExpress.XtraEditors.CheckEdit();
            ((System.ComponentModel.ISupportInitialize)(this.xtraTabControl1)).BeginInit();
            this.xtraTabControl1.SuspendLayout();
            this.tbLedgers.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dtEnd.Properties.CalendarTimeProperties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtEnd.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbLedger.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtStart.Properties.CalendarTimeProperties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtStart.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.chkAll.Properties)).BeginInit();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Location = new System.Drawing.Point(0, 198);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(532, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // xtraTabControl1
            // 
            this.xtraTabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.xtraTabControl1.Location = new System.Drawing.Point(0, 0);
            this.xtraTabControl1.Name = "xtraTabControl1";
            this.xtraTabControl1.SelectedTabPage = this.tbLedgers;
            this.xtraTabControl1.Size = new System.Drawing.Size(532, 198);
            this.xtraTabControl1.TabIndex = 1;
            this.xtraTabControl1.TabPages.AddRange(new DevExpress.XtraTab.XtraTabPage[] {
            this.tbLedgers});
            // 
            // tbLedgers
            // 
            this.tbLedgers.Controls.Add(this.chkAll);
            this.tbLedgers.Controls.Add(this.labelControl3);
            this.tbLedgers.Controls.Add(this.dtEnd);
            this.tbLedgers.Controls.Add(this.cmbLedger);
            this.tbLedgers.Controls.Add(this.btnViewLedger);
            this.tbLedgers.Controls.Add(this.btnClose);
            this.tbLedgers.Controls.Add(this.dtStart);
            this.tbLedgers.Controls.Add(this.labelControl2);
            this.tbLedgers.Controls.Add(this.labelControl1);
            this.tbLedgers.Name = "tbLedgers";
            this.tbLedgers.Size = new System.Drawing.Size(526, 170);
            this.tbLedgers.Text = "View Ledger";
            // 
            // labelControl3
            // 
            this.labelControl3.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.labelControl3.Location = new System.Drawing.Point(259, 61);
            this.labelControl3.Name = "labelControl3";
            this.labelControl3.Size = new System.Drawing.Size(45, 16);
            this.labelControl3.TabIndex = 7;
            this.labelControl3.Text = "To Date";
            // 
            // dtEnd
            // 
            this.dtEnd.EditValue = null;
            this.dtEnd.Location = new System.Drawing.Point(315, 58);
            this.dtEnd.Name = "dtEnd";
            this.dtEnd.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.dtEnd.Properties.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.dtEnd.Properties.Appearance.Options.UseFont = true;
            this.dtEnd.Properties.Appearance.Options.UseForeColor = true;
            this.dtEnd.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtEnd.Properties.CalendarTimeProperties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtEnd.Size = new System.Drawing.Size(152, 22);
            this.dtEnd.TabIndex = 6;
            // 
            // cmbLedger
            // 
            this.cmbLedger.Location = new System.Drawing.Point(97, 26);
            this.cmbLedger.Name = "cmbLedger";
            this.cmbLedger.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.cmbLedger.Properties.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.cmbLedger.Properties.Appearance.Options.UseFont = true;
            this.cmbLedger.Properties.Appearance.Options.UseForeColor = true;
            this.cmbLedger.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.cmbLedger.Size = new System.Drawing.Size(370, 22);
            this.cmbLedger.TabIndex = 5;
            this.cmbLedger.SelectedValueChanged += new System.EventHandler(this.cmbLedger_SelectedValueChanged);
            // 
            // btnViewLedger
            // 
            this.btnViewLedger.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnViewLedger.Location = new System.Drawing.Point(353, 121);
            this.btnViewLedger.Name = "btnViewLedger";
            this.btnViewLedger.Size = new System.Drawing.Size(75, 23);
            this.btnViewLedger.TabIndex = 4;
            this.btnViewLedger.Text = "View";
            this.btnViewLedger.Click += new System.EventHandler(this.btnViewLedger_Click);
            // 
            // btnClose
            // 
            this.btnClose.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnClose.Location = new System.Drawing.Point(435, 121);
            this.btnClose.Name = "btnClose";
            this.btnClose.Size = new System.Drawing.Size(75, 23);
            this.btnClose.TabIndex = 3;
            this.btnClose.Text = "Close";
            this.btnClose.Click += new System.EventHandler(this.btnClose_Click);
            // 
            // dtStart
            // 
            this.dtStart.EditValue = null;
            this.dtStart.Location = new System.Drawing.Point(97, 58);
            this.dtStart.Name = "dtStart";
            this.dtStart.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.dtStart.Properties.Appearance.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(192)))));
            this.dtStart.Properties.Appearance.Options.UseFont = true;
            this.dtStart.Properties.Appearance.Options.UseForeColor = true;
            this.dtStart.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtStart.Properties.CalendarTimeProperties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtStart.Size = new System.Drawing.Size(138, 22);
            this.dtStart.TabIndex = 2;
            // 
            // labelControl2
            // 
            this.labelControl2.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.labelControl2.Location = new System.Drawing.Point(25, 61);
            this.labelControl2.Name = "labelControl2";
            this.labelControl2.Size = new System.Drawing.Size(60, 16);
            this.labelControl2.TabIndex = 1;
            this.labelControl2.Text = "From Date";
            // 
            // labelControl1
            // 
            this.labelControl1.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.labelControl1.Location = new System.Drawing.Point(35, 29);
            this.labelControl1.Name = "labelControl1";
            this.labelControl1.Size = new System.Drawing.Size(39, 16);
            this.labelControl1.TabIndex = 0;
            this.labelControl1.Text = "Ledger";
            // 
            // chkAll
            // 
            this.chkAll.Location = new System.Drawing.Point(472, 28);
            this.chkAll.Name = "chkAll";
            this.chkAll.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 8.25F, System.Drawing.FontStyle.Bold);
            this.chkAll.Properties.Appearance.Options.UseFont = true;
            this.chkAll.Properties.Caption = "All";
            this.chkAll.Size = new System.Drawing.Size(47, 19);
            this.chkAll.TabIndex = 8;
            this.chkAll.CheckedChanged += new System.EventHandler(this.chkAll_CheckedChanged);
            this.chkAll.Click += new System.EventHandler(this.chkAll_Click);
            // 
            // SelectReport
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(532, 220);
            this.Controls.Add(this.xtraTabControl1);
            this.Controls.Add(this.statusStrip1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "SelectReport";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Select Report";
            this.Load += new System.EventHandler(this.SelectReport_Load);
            ((System.ComponentModel.ISupportInitialize)(this.xtraTabControl1)).EndInit();
            this.xtraTabControl1.ResumeLayout(false);
            this.tbLedgers.ResumeLayout(false);
            this.tbLedgers.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dtEnd.Properties.CalendarTimeProperties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtEnd.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbLedger.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtStart.Properties.CalendarTimeProperties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtStart.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.chkAll.Properties)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraTab.XtraTabControl xtraTabControl1;
        private DevExpress.XtraTab.XtraTabPage tbLedgers;
        private DevExpress.XtraEditors.LabelControl labelControl3;
        private DevExpress.XtraEditors.DateEdit dtEnd;
        private DevExpress.XtraEditors.ComboBoxEdit cmbLedger;
        private DevExpress.XtraEditors.SimpleButton btnViewLedger;
        private DevExpress.XtraEditors.SimpleButton btnClose;
        private DevExpress.XtraEditors.DateEdit dtStart;
        private DevExpress.XtraEditors.LabelControl labelControl2;
        private DevExpress.XtraEditors.LabelControl labelControl1;
        private DevExpress.XtraEditors.CheckEdit chkAll;
    }
}