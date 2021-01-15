namespace Reports
{
    partial class ClientBalances
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
            this.dtDate = new DevExpress.XtraEditors.DateEdit();
            this.labelControl1 = new DevExpress.XtraEditors.LabelControl();
            this.btnView = new DevExpress.XtraEditors.SimpleButton();
            this.rdoCreditors = new System.Windows.Forms.RadioButton();
            this.rdoDebtors = new System.Windows.Forms.RadioButton();
            this.rdoAll = new System.Windows.Forms.RadioButton();
            ((System.ComponentModel.ISupportInitialize)(this.dtDate.Properties.CalendarTimeProperties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDate.Properties)).BeginInit();
            this.SuspendLayout();
            // 
            // dtDate
            // 
            this.dtDate.EditValue = null;
            this.dtDate.Location = new System.Drawing.Point(136, 75);
            this.dtDate.Name = "dtDate";
            this.dtDate.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtDate.Properties.CalendarTimeProperties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtDate.Properties.DisplayFormat.FormatString = "yyyy/MM/dd";
            this.dtDate.Properties.DisplayFormat.FormatType = DevExpress.Utils.FormatType.DateTime;
            this.dtDate.Properties.EditFormat.FormatString = "yyyy/MM/dd";
            this.dtDate.Properties.EditFormat.FormatType = DevExpress.Utils.FormatType.DateTime;
            this.dtDate.Size = new System.Drawing.Size(207, 20);
            this.dtDate.TabIndex = 0;
            // 
            // labelControl1
            // 
            this.labelControl1.Location = new System.Drawing.Point(41, 82);
            this.labelControl1.Name = "labelControl1";
            this.labelControl1.Size = new System.Drawing.Size(70, 13);
            this.labelControl1.TabIndex = 1;
            this.labelControl1.Text = "Balances as At";
            // 
            // btnView
            // 
            this.btnView.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnView.Location = new System.Drawing.Point(268, 120);
            this.btnView.Name = "btnView";
            this.btnView.Size = new System.Drawing.Size(75, 23);
            this.btnView.TabIndex = 2;
            this.btnView.Text = "View";
            this.btnView.Click += new System.EventHandler(this.btnView_Click);
            // 
            // rdoCreditors
            // 
            this.rdoCreditors.AutoSize = true;
            this.rdoCreditors.Location = new System.Drawing.Point(193, 43);
            this.rdoCreditors.Name = "rdoCreditors";
            this.rdoCreditors.Size = new System.Drawing.Size(66, 17);
            this.rdoCreditors.TabIndex = 3;
            this.rdoCreditors.TabStop = true;
            this.rdoCreditors.Text = "Creditors";
            this.rdoCreditors.UseVisualStyleBackColor = true;
            // 
            // rdoDebtors
            // 
            this.rdoDebtors.AutoSize = true;
            this.rdoDebtors.Location = new System.Drawing.Point(113, 43);
            this.rdoDebtors.Name = "rdoDebtors";
            this.rdoDebtors.Size = new System.Drawing.Size(62, 17);
            this.rdoDebtors.TabIndex = 4;
            this.rdoDebtors.TabStop = true;
            this.rdoDebtors.Text = "Debtors";
            this.rdoDebtors.UseVisualStyleBackColor = true;
            // 
            // rdoAll
            // 
            this.rdoAll.AutoSize = true;
            this.rdoAll.Location = new System.Drawing.Point(268, 43);
            this.rdoAll.Name = "rdoAll";
            this.rdoAll.Size = new System.Drawing.Size(36, 17);
            this.rdoAll.TabIndex = 5;
            this.rdoAll.TabStop = true;
            this.rdoAll.Text = "All";
            this.rdoAll.UseVisualStyleBackColor = true;
            // 
            // ClientBalances
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(401, 170);
            this.Controls.Add(this.rdoAll);
            this.Controls.Add(this.rdoDebtors);
            this.Controls.Add(this.rdoCreditors);
            this.Controls.Add(this.btnView);
            this.Controls.Add(this.labelControl1);
            this.Controls.Add(this.dtDate);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.Name = "ClientBalances";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Client Balances";
            this.Load += new System.EventHandler(this.ClientBalances_Load);
            ((System.ComponentModel.ISupportInitialize)(this.dtDate.Properties.CalendarTimeProperties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtDate.Properties)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private DevExpress.XtraEditors.DateEdit dtDate;
        private DevExpress.XtraEditors.LabelControl labelControl1;
        private DevExpress.XtraEditors.SimpleButton btnView;
        private System.Windows.Forms.RadioButton rdoCreditors;
        private System.Windows.Forms.RadioButton rdoDebtors;
        private System.Windows.Forms.RadioButton rdoAll;
    }
}