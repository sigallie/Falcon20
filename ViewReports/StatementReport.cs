using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;
using DevExpress.DataAccess.Sql;
using DevExpress.DataAccess.ConnectionParameters;

using GenLib;

namespace ViewReports
{
    public partial class StatementReport : DevExpress.XtraReports.UI.XtraReport
    {
        public StatementReport()
        {
            InitializeComponent();
        }

        private void sqlDataSource1_ConfigureDataConnection(object sender, DevExpress.DataAccess.Sql.ConfigureDataConnectionEventArgs e)
        {
            string connectionString = @"XpoProvider=MSSqlServer;Data Source=('" + ClassGenLib.ServerIP + "');User ID=sa;Password=;Initial Catalog=database;Persist Security Info=true;";
            CustomStringConnectionParameters connectionParameters = new CustomStringConnectionParameters(connectionString);
            SqlDataSource ds = new SqlDataSource(connectionParameters);
        }

    }
}
