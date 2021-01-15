using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;
using System.Data.SqlClient;
using System.Configuration;
using DevExpress.DataAccess.Sql;
using DevExpress.DataAccess.ConnectionParameters;

using GenLib;

namespace ViewReports
{
    public partial class BNOTE : DevExpress.XtraReports.UI.XtraReport
    {
        public BNOTE()
        {
            InitializeComponent();
        }

        private void sqlDataSource1_ConfigureDataConnection(object sender, DevExpress.DataAccess.Sql.ConfigureDataConnectionEventArgs e)
        {
            //using (var settings = new ApplicationSettings())
            //{
            //    var sqlConnection = new SqlConnection(settings.GetConnectionString("connBNOTE"));
            //    var sqlConnectionStringBuilder = new SqlConnectionStringBuilder(sqlConnection.ConnectionString);
            //    var dataConnectionParametersBase = new MsSqlConnectionParameters
            //    {
            //        ServerName = sqlConnectionStringBuilder.DataSource,
            //        DatabaseName = sqlConnectionStringBuilder.InitialCatalog,
            //        UserName = sqlConnectionStringBuilder.UserID,
            //        Password = sqlConnectionStringBuilder.Password,
            //        AuthorizationType = sqlConnectionStringBuilder.IntegratedSecurity ? MsSqlAuthorizationType.Windows : MsSqlAuthorizationType.SqlServer
            //    };
            //    e.ConnectionParameters = dataConnectionParametersBase;
            //}

            //string connectionString = @"XpoProvider=MSSqlServer;Data Source=('"+ClassGenLib.ServerIP+"');User ID=sa;Password=;Initial Catalog=database;Persist Security Info=true;";
            string connectionString = @"XpoProvider=MSSqlServer;data source=.;User ID=sa;Password=;Initial Catalog=NewFalconTest;Persist Security Info=true;";
            CustomStringConnectionParameters connectionParameters = new CustomStringConnectionParameters(connectionString);
            SqlDataSource ds = new SqlDataSource(connectionParameters);
            //this.DataSource = ds;
        }

        private void xrLabel62_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
        {

        }
    }
}
