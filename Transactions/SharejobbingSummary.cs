using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;

using DBUtils;
using GenLib;

namespace Transactions
{
    public partial class SharejobbingSummary : Form
    {
        public SharejobbingSummary()
        {
            InitializeComponent();
        }

        private void labelControl1_Click(object sender, EventArgs e)
        {

        }

        private void btnView_Click(object sender, EventArgs e)
        {
            if(dtFrom.Text == "" || dtTo.Text == "")
            {
                MessageBox.Show("Specify all the dates!");
                return;
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string strSQL = "select dealdate, cons from sharejobbingsummary where username = '"+ClassGenLib.username+"' and cons <> 0";

                    SqlCommand cmd = new SqlCommand("spSharejobbingSummary", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 12000;
                    SqlParameter p1 = new SqlParameter("@start", dtFrom.DateTime.Date);
                    SqlParameter p2 = new SqlParameter("@end", dtTo.DateTime.Date);
                    SqlParameter p3 = new SqlParameter("@user", ClassGenLib.username);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3);
                    cmd.ExecuteNonQuery();

                    using(SqlDataAdapter da = new SqlDataAdapter(strSQL, conn))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        grdSharejob.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }
    }
}
