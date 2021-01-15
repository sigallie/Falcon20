using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;
using DevExpress.DataAccess.ConnectionParameters;
using DevExpress.DataAccess.Sql;

using GenLib;
using DBUtils;

namespace ViewReports
{
    public partial class SNOTE : DevExpress.XtraReports.UI.XtraReport
    {
        public SNOTE()
        {
            InitializeComponent();
        }

        private void sqlDataSource1_ConfigureDataConnection(object sender, DevExpress.DataAccess.Sql.ConfigureDataConnectionEventArgs e)
        {
            //string connectionString = @"XpoProvider=MSSqlServer;Data Source=('" + ClassGenLib.ServerIP + "');User ID=sa;Password=;Initial Catalog=database;Persist Security Info=true;";
            //CustomStringConnectionParameters connectionParameters = new CustomStringConnectionParameters(connectionString);
            //SqlDataSource ds = new SqlDataSource(connectionParameters);
            //this.DataSource = ds;

            string connectionString = @"XpoProvider=MSSqlServer;Data Source=('" + ClassGenLib.ServerIP + "');User ID=sa;Password=;Initial Catalog=database;Persist Security Info=true;";
            CustomStringConnectionParameters connectionParameters = new CustomStringConnectionParameters(connectionString);
            SqlDataSource ds = new SqlDataSource(connectionParameters);
            sqlDataSource1.Connection.ConnectionString = ClassDBUtils.DBConnString;
        }

    }
}
