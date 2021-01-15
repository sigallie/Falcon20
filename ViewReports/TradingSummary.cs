using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;

using DevExpress.DataAccess.Sql;
using DevExpress.DataAccess.ConnectionParameters;

namespace ViewReports
{
    public partial class TradingSummary : DevExpress.XtraReports.UI.XtraReport
    {
        public TradingSummary()
        {
            InitializeComponent();
        }

        private void xrLabel13_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
        {

        }

        private void sqlDataSource1_ConfigureDataConnection(object sender, DevExpress.DataAccess.Sql.ConfigureDataConnectionEventArgs e)
        {
            e.ConnectionParameters = new MsSqlConnectionParameters(".", "Newfalcon20", "sa", "", MsSqlAuthorizationType.SqlServer);
        }

    }
}
