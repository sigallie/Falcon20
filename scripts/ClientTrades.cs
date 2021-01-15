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

namespace Clients
{
    public partial class ClientTrades : Form
    {
        public ClientTrades()
        {
            InitializeComponent();
        }

        private void txtClient_ButtonClick(object sender, DevExpress.XtraEditors.Controls.ButtonPressedEventArgs e)
        {
            ClientListing lst = new ClientListing();
            lst.ShowDialog();

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    string strSQL = "select * from vwDealAllocations where clientno = '" + ClassGenLib.selectedClient + "' order by dealdate, id";

                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    using(SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdTrades.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
        }

        private void ClientTrades_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.F10)
            {
                //dea
            }
        }
    }
}
