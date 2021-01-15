namespace Reports
{
    partial class frmClientStatement
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
            this.dtStart = new DevExpress.XtraEditors.DateEdit();
            this.txtClient = new DevExpress.XtraEditors.ButtonEdit();
            this.labelControl1 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl2 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl3 = new DevExpress.XtraEditors.LabelControl();
            this.dtEnd = new DevExpress.XtraEditors.DateEdit();
            this.btnClose = new DevExpress.XtraEditors.SimpleButton();
            this.btnView = new DevExpress.XtraEditors.SimpleButton();
            ((System.ComponentModel.ISupportInitialize)(this.dtStart.Properties.CalendarTimeProperties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtStart.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtClient.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtEnd.Properties.CalendarTimeProperties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtEnd.Properties)).BeginInit();
            this.SuspendLayout();
            // 
            // statusStrip1
            // 
            this.statusStrip1.Location = new System.Drawing.Point(0, 168);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(602, 22);
            this.statusStrip1.TabIndex = 0;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // dtStart
            // 
            this.dtStart.EditValue = null;
            this.dtStart.Location = new System.Drawing.Point(129, 78);
            this.dtStart.Name = "dtStart";
            this.dtStart.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.dtStart.Properties.Appearance.ForeColor = System.Drawing.Color.Blue;
            this.dtStart.Properties.Appearance.Options.UseFont = true;
            this.dtStart.Properties.Appearance.Options.UseForeColor = true;
            this.dtStart.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.dtStart.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtStart.Properties.CalendarTimeProperties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtStart.Properties.EditFormat.FormatString = "yyyy/MM/dd";
            this.dtStart.Properties.EditFormat.FormatType = DevExpress.Utils.FormatType.DateTime;
            this.dtStart.Properties.Mask.EditMask = "yyyy/MM/dd";
            this.dtStart.Size = new System.Drawing.Size(172, 24);
            this.dtStart.TabIndex = 1;
            // 
            // txtClient
            // 
            this.txtClient.Location = new System.Drawing.Point(129, 36);
            this.txtClient.Name = "txtClient";
            this.txtClient.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.txtClient.Properties.Appearance.ForeColor = System.Drawing.Color.Blue;
            this.txtClient.Properties.Appearance.Options.UseFont = true;
            this.txtClient.Properties.Appearance.Options.UseForeColor = true;
            this.txtClient.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.txtClient.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton()});
            this.txtClient.Size = new System.Drawing.Size(463, 24);
            this.txtClient.TabIndex = 2;
            this.txtClient.ButtonClick += new DevExpress.XtraEditors.Controls.ButtonPressedEventHandler(this.txtClient_ButtonClick);
            // 
            // labelControl1
            // 
            this.labelControl1.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.labelControl1.Location = new System.Drawing.Point(77, 39);
            this.labelControl1.Name = "labelControl1";
            this.labelControl1.Size = new System.Drawing.Size(32, 16);
            this.labelControl1.TabIndex = 3;
            this.labelControl1.Text = "Client";
            // 
            // labelControl2
            // 
            this.labelControl2.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.labelControl2.Location = new System.Drawing.Point(54, 81);
            this.labelControl2.Name = "labelControl2";
            this.labelControl2.Size = new System.Drawing.Size(58, 16);
            this.labelControl2.TabIndex = 4;
            this.labelControl2.Text = "Start Date";
            // 
            // labelControl3
            // 
            this.labelControl3.Appearance.Font = new System.Drawing.Font("Tahoma", 10F);
            this.labelControl3.Location = new System.Drawing.Point(328, 84);
            this.labelControl3.Name = "labelControl3";
            this.labelControl3.Size = new System.Drawing.Size(51, 16);
            this.labelControl3.TabIndex = 5;
            this.labelControl3.Text = "End Date";
            // 
            // dtEnd
            // 
            this.dtEnd.EditValue = null;
            this.dtEnd.Location = new System.Drawing.Point(392, 81);
            this.dtEnd.Name = "dtEnd";
            this.dtEnd.Properties.Appearance.Font = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
            this.dtEnd.Properties.Appearance.ForeColor = System.Drawing.Color.Blue;
            this.dtEnd.Properties.Appearance.Options.UseFont = true;
            this.dtEnd.Properties.Appearance.Options.UseForeColor = true;
            this.dtEnd.Properties.BorderStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.dtEnd.Properties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtEnd.Properties.CalendarTimeProperties.Buttons.AddRange(new DevExpress.XtraEditors.Controls.EditorButton[] {
            new DevExpress.XtraEditors.Controls.EditorButton(DevExpress.XtraEditors.Controls.ButtonPredefines.Combo)});
            this.dtEnd.Properties.EditFormat.FormatString = "yyyy/MM/dd";
            this.dtEnd.Properties.EditFormat.FormatType = DevExpress.Utils.FormatType.DateTime;
            this.dtEnd.Properties.Mask.EditMask = "yyyy/MM/dd";
            this.dtEnd.Size = new System.Drawing.Size(200, 24);
            this.dtEnd.TabIndex = 6;
            // 
            // btnClose
            // 
            this.btnClose.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnClose.Location = new System.Drawing.Point(517, 131);
            this.btnClose.Name = "btnClose";
            this.btnClose.Size = new System.Drawing.Size(75, 23);
            this.btnClose.TabIndex = 7;
            this.btnClose.Text = "Close";
            this.btnClose.Click += new System.EventHandler(this.simpleButton1_Click);
            // 
            // btnView
            // 
            this.btnView.ButtonStyle = DevExpress.XtraEditors.Controls.BorderStyles.HotFlat;
            this.btnView.Location = new System.Drawing.Point(422, 131);
            this.btnView.Name = "btnView";
            this.btnView.Size = new System.Drawing.Size(75, 23);
            this.btnView.TabIndex = 8;
            this.btnView.Text = "View";
            this.btnView.Click += new System.EventHandler(this.btnView_Click);
            // 
            // frmClientStatement
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(602, 190);
            this.Controls.Add(this.btnView);
            this.Controls.Add(this.btnClose);
            this.Controls.Add(this.dtEnd);
            this.Controls.Add(this.labelControl3);
            this.Controls.Add(this.labelControl2);
            this.Controls.Add(this.labelControl1);
            this.Controls.Add(this.txtClient);
            this.Controls.Add(this.dtStart);
            this.Controls.Add(this.statusStrip1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "frmClientStatement";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "View Client Statement";
            this.Load += new System.EventHandler(this.frmClientStatement_Load);
            ((System.ComponentModel.ISupportInitialize)(this.dtStart.Properties.CalendarTimeProperties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtStart.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtClient.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtEnd.Properties.CalendarTimeProperties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtEnd.Properties)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private DevExpress.XtraEditors.DateEdit dtStart;
        private DevExpress.XtraEditors.ButtonEdit txtClient;
        private DevExpress.XtraEditors.LabelControl labelControl1;
        private DevExpress.XtraEditors.LabelControl labelControl2;
        private DevExpress.XtraEditors.LabelControl labelControl3;
        private DevExpress.XtraEditors.DateEdit dtEnd;
        private DevExpress.XtraEditors.SimpleButton btnClose;
        private DevExpress.XtraEditors.SimpleButton btnView;
    }
}