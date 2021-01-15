namespace Transactions
{
    partial class TaxPayments
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
            this.grpTax = new DevExpress.XtraEditors.GroupControl();
            this.dtpTime = new System.Windows.Forms.DateTimePicker();
            this.labelControl3 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl2 = new DevExpress.XtraEditors.LabelControl();
            this.txtClientNo = new DevExpress.XtraEditors.TextEdit();
            this.labelControl1 = new DevExpress.XtraEditors.LabelControl();
            this.dtDate = new DevExpress.XtraEditors.DateEdit();
            this.cmbTransType = new DevExpress.XtraEditors.ComboBoxEdit();
            this.txtAmountOwing = new DevExpress.XtraEditors.TextEdit();
            this.labelControl4 = new DevExpress.XtraEditors.LabelControl();
            this.txtComment = new DevExpress.XtraEditors.TextEdit();
            this.labelControl5 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl6 = new DevExpress.XtraEditors.LabelControl();
            this.cmbTransAccount = new DevExpress.XtraEditors.ComboBoxEdit();
            this.labelControl7 = new DevExpress.XtraEditors.LabelControl();
            this.cmbMethod = new DevExpress.XtraEditors.ComboBoxEdit();
            this.txtAmount = new DevExpress.XtraEditors.TextEdit();
            this.labelControl8 = new DevExpress.XtraEditors.LabelControl();
            this.btnProcess = new DevExpress.XtraEditors.SimpleButton();
            this.btnClose = new DevExpress.XtraEditors.SimpleButton();
            this.chkAmountOwing = new DevExpress.XtraEditors.CheckEdit();
            ((System.ComponentModel.ISupportInitialize)(this.grpTax)).BeginInit();
            this.grpTax.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.txtClientNo.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDate.Properties.CalendarTimeProperties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDate.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbTransType.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtAmountOwing.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtComment.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbTransAccount.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbMethod.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtAmount.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.chkAmountOwing.Properties)).BeginInit();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Location = new System.Drawing.Point(0, 289);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(591, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // grpTax
            // 
            this.grpTax.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.grpTax.CaptionLocation = DevExpress.Utils.Locations.Top;
            this.grpTax.Controls.Add(this.dtpTime);
            this.grpTax.Controls.Add(this.labelControl3);
            this.grpTax.Controls.Add(this.labelControl2);
            this.grpTax.Controls.Add(this.txtClientNo);
            this.grpTax.Controls.Add(this.labelControl1);
            this.grpTax.Controls.Add(this.dtDate);
            this.grpTax.Controls.Add(this.cmbTransType);
            this.grpTax.Location = new System.Drawing.Point(0, 12);
            this.grpTax.LookAndFeel.SkinName = "DevExpress Dark Style";
            this.grpTax.LookAndFeel.Style = DevExpress.LookAndFeel.LookAndFeelStyle.Office2003;
            this.grpTax.LookAndFeel.UseDefaultLookAndFeel = false;
            this.grpTax.Name = "grpTax";
            this.grpTax.Size = new System.Drawing.Size(591, 122);
            this.grpTax.TabIndex = 1;
            this.grpTax.Paint += new System.Windows.Forms.PaintEventHandler(this.grpTax_Paint);
            // 
            // dtpTime
            // 
            this.dtpTime.Enabled = false;
            this.dtpTime.Format = System.Windows.Forms.DateTimePickerFormat.Time;
            this.dtpTime.Location = new System.Drawing.Point(423, 34);
            this.dtpTime.Name = "dtpTime";
            this.dtpTime.Size = new System.Drawing.Size(120, 21);
            this.dtpTime.TabIndex = 17;
            this.dtpTime.Visible = false;
            // 
            // labelControl3
            // 
            this.labelControl3.Location = new System.Drawing.Point(12, 59);
            this.labelControl3.Name = "labelControl3";
            this.labelControl3.Size = new System.Drawing.Size(82, 13);
            this.labelControl3.TabIndex = 5;
            this.labelControl3.Text = "Transaction Date";
            // 
            // labelControl2
            // 
            this.labelControl2.Location = new System.Drawing.Point(12, 36);
            this.labelControl2.Name = "labelControl2";
            this.labelControl2.Size = new System.Drawing.Size(83, 13);
            this.labelControl2.TabIndex = 4;
            this.labelControl2.Text = "Transaction Type";
            // 
            // txtClientNo
            // 
            this.txtClientNo.Location = new System.Drawing.Point(104, 85);
            this.txtClientNo.Name = "txtClientNo";
            this.txtClientNo.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.txtClientNo.Size = new System.Drawing.Size(295, 22);
            this.txtClientNo.TabIndex = 3;
            // 
            // labelControl1
            // 
            this.labelControl1.Location = new System.Drawing.Point(12, 82);
            this.labelControl1.Name = "labelControl1";
            this.labelControl1.Size = new System.Drawing.Size(38, 13);
            this.labelControl1.TabIndex = 2;
            this.labelControl1.Text = "Client #";
            // 
            // dtDate
            // 
            this.dtDate.EditValue = null;
            this.dtDate.Location = new System.Drawing.Point(104, 59);
            this.dtDate.Name = "dtDate";
            this.dtDate.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.dtDate.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtDate.Properties.CalendarTimeProperties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtDate.Size = new System.Drawing.Size(295, 22);
            this.dtDate.TabIndex = 1;
            // 
            // cmbTransType
            // 
            this.cmbTransType.Location = new System.Drawing.Point(104, 33);
            this.cmbTransType.Name = "cmbTransType";
            this.cmbTransType.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.cmbTransType.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.cmbTransType.Size = new System.Drawing.Size(295, 22);
            this.cmbTransType.TabIndex = 0;
            this.cmbTransType.SelectedValueChanged += new System.EventHandler(this.cmbTransType_SelectedValueChanged);
            // 
            // txtAmountOwing
            // 
            this.txtAmountOwing.Location = new System.Drawing.Point(104, 162);
            this.txtAmountOwing.Name = "txtAmountOwing";
            this.txtAmountOwing.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.txtAmountOwing.Properties.ReadOnly = true;
            this.txtAmountOwing.Size = new System.Drawing.Size(185, 22);
            this.txtAmountOwing.TabIndex = 5;
            // 
            // labelControl4
            // 
            this.labelControl4.Location = new System.Drawing.Point(12, 167);
            this.labelControl4.Name = "labelControl4";
            this.labelControl4.Size = new System.Drawing.Size(70, 13);
            this.labelControl4.TabIndex = 4;
            this.labelControl4.Text = "Amount Owing";
            // 
            // txtComment
            // 
            this.txtComment.Location = new System.Drawing.Point(104, 234);
            this.txtComment.Name = "txtComment";
            this.txtComment.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.txtComment.Properties.CharacterCasing = System.Windows.Forms.CharacterCasing.Upper;
            this.txtComment.Size = new System.Drawing.Size(475, 22);
            this.txtComment.TabIndex = 7;
            // 
            // labelControl5
            // 
            this.labelControl5.Location = new System.Drawing.Point(12, 231);
            this.labelControl5.Name = "labelControl5";
            this.labelControl5.Size = new System.Drawing.Size(45, 13);
            this.labelControl5.TabIndex = 6;
            this.labelControl5.Text = "Comment";
            // 
            // labelControl6
            // 
            this.labelControl6.Location = new System.Drawing.Point(12, 200);
            this.labelControl6.Name = "labelControl6";
            this.labelControl6.Size = new System.Drawing.Size(80, 13);
            this.labelControl6.TabIndex = 9;
            this.labelControl6.Text = "Transaction Acct";
            // 
            // cmbTransAccount
            // 
            this.cmbTransAccount.Location = new System.Drawing.Point(104, 195);
            this.cmbTransAccount.Name = "cmbTransAccount";
            this.cmbTransAccount.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.cmbTransAccount.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.cmbTransAccount.Size = new System.Drawing.Size(185, 22);
            this.cmbTransAccount.TabIndex = 8;
            this.cmbTransAccount.SelectedValueChanged += new System.EventHandler(this.cmbTransAccount_SelectedValueChanged);
            // 
            // labelControl7
            // 
            this.labelControl7.Location = new System.Drawing.Point(296, 200);
            this.labelControl7.Name = "labelControl7";
            this.labelControl7.Size = new System.Drawing.Size(81, 13);
            this.labelControl7.TabIndex = 11;
            this.labelControl7.Text = "Payment Method";
            // 
            // cmbMethod
            // 
            this.cmbMethod.Location = new System.Drawing.Point(394, 195);
            this.cmbMethod.Name = "cmbMethod";
            this.cmbMethod.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.cmbMethod.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.cmbMethod.Properties.Items.AddRange(new object[] {
            "BANK TRANSFER",
            "CASH"});
            this.cmbMethod.Size = new System.Drawing.Size(185, 22);
            this.cmbMethod.TabIndex = 10;
            // 
            // txtAmount
            // 
            this.txtAmount.Location = new System.Drawing.Point(394, 162);
            this.txtAmount.Name = "txtAmount";
            this.txtAmount.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.txtAmount.Size = new System.Drawing.Size(185, 22);
            this.txtAmount.TabIndex = 13;
            // 
            // labelControl8
            // 
            this.labelControl8.Location = new System.Drawing.Point(296, 167);
            this.labelControl8.Name = "labelControl8";
            this.labelControl8.Size = new System.Drawing.Size(96, 13);
            this.labelControl8.TabIndex = 12;
            this.labelControl8.Text = "Transaction Amount";
            // 
            // btnProcess
            // 
            this.btnProcess.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnProcess.Location = new System.Drawing.Point(423, 261);
            this.btnProcess.Name = "btnProcess";
            this.btnProcess.Size = new System.Drawing.Size(75, 23);
            this.btnProcess.TabIndex = 14;
            this.btnProcess.Text = "Process";
            this.btnProcess.Click += new System.EventHandler(this.btnProcess_Click);
            // 
            // btnClose
            // 
            this.btnClose.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnClose.Location = new System.Drawing.Point(504, 261);
            this.btnClose.Name = "btnClose";
            this.btnClose.Size = new System.Drawing.Size(75, 23);
            this.btnClose.TabIndex = 15;
            this.btnClose.Text = "Close";
            this.btnClose.Click += new System.EventHandler(this.btnClose_Click);
            // 
            // chkAmountOwing
            // 
            this.chkAmountOwing.Location = new System.Drawing.Point(424, 137);
            this.chkAmountOwing.Name = "chkAmountOwing";
            this.chkAmountOwing.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.chkAmountOwing.Properties.Caption = "Pay Amount Owing";
            this.chkAmountOwing.Size = new System.Drawing.Size(155, 23);
            this.chkAmountOwing.TabIndex = 16;
            this.chkAmountOwing.CheckedChanged += new System.EventHandler(this.chkAmountOwing_CheckedChanged);
            // 
            // TaxPayments
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(591, 311);
            this.Controls.Add(this.chkAmountOwing);
            this.Controls.Add(this.btnClose);
            this.Controls.Add(this.btnProcess);
            this.Controls.Add(this.txtAmount);
            this.Controls.Add(this.labelControl8);
            this.Controls.Add(this.labelControl7);
            this.Controls.Add(this.cmbMethod);
            this.Controls.Add(this.labelControl6);
            this.Controls.Add(this.cmbTransAccount);
            this.Controls.Add(this.txtComment);
            this.Controls.Add(this.labelControl5);
            this.Controls.Add(this.txtAmountOwing);
            this.Controls.Add(this.labelControl4);
            this.Controls.Add(this.grpTax);
            this.Controls.Add(this.statusStrip1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "TaxPayments";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Process Statutory Payment";
            this.Load += new System.EventHandler(this.TaxPayments_Load);
            ((System.ComponentModel.ISupportInitialize)(this.grpTax)).EndInit();
            this.grpTax.ResumeLayout(false);
            this.grpTax.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.txtClientNo.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDate.Properties.CalendarTimeProperties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDate.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbTransType.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtAmountOwing.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtComment.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbTransAccount.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.cmbMethod.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtAmount.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.chkAmountOwing.Properties)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraEditors.GroupControl grpTax;
        private DevExpress.XtraEditors.TextEdit txtClientNo;
        private DevExpress.XtraEditors.LabelControl labelControl1;
        private DevExpress.XtraEditors.DateEdit dtDate;
        private DevExpress.XtraEditors.ComboBoxEdit cmbTransType;
        private DevExpress.XtraEditors.LabelControl labelControl3;
        private DevExpress.XtraEditors.LabelControl labelControl2;
        private DevExpress.XtraEditors.TextEdit txtAmountOwing;
        private DevExpress.XtraEditors.LabelControl labelControl4;
        private DevExpress.XtraEditors.TextEdit txtComment;
        private DevExpress.XtraEditors.LabelControl labelControl5;
        private DevExpress.XtraEditors.LabelControl labelControl6;
        private DevExpress.XtraEditors.ComboBoxEdit cmbTransAccount;
        private DevExpress.XtraEditors.LabelControl labelControl7;
        private DevExpress.XtraEditors.ComboBoxEdit cmbMethod;
        private DevExpress.XtraEditors.TextEdit txtAmount;
        private DevExpress.XtraEditors.LabelControl labelControl8;
        private DevExpress.XtraEditors.SimpleButton btnProcess;
        private DevExpress.XtraEditors.SimpleButton btnClose;
        private DevExpress.XtraEditors.CheckEdit chkAmountOwing;
        private System.Windows.Forms.DateTimePicker dtpTime;
    }
}