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

using GenLib;
using DBUtils;

namespace Clients
{
    public partial class ClientListing : Form
    {
        public ClientListing()
        {
            InitializeComponent();
        }

        private void ClientListing_Load(object sender, EventArgs e)
        {
            
            //txtClient.Focus();

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string strSQL = "select * from vwClientListing where category <> 'BROKER' and clientname like '%"+txtClient.Text+"%' order by clientname";

                    using(SqlDataAdapter da = new SqlDataAdapter(strSQL, conn))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        grdClients.DataSource = dt;
                    }
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
            txtClient.Focus();
        }

        private void vwClients_DoubleClick(object sender, EventArgs e)
        {
            //set the selected client as the current client and exit the window
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    for(int i = 0; i < vwClients.RowCount; i++)
                    {
                        if(vwClients.IsRowSelected(i))
                        {
                            ClassGenLib.selectedClient = vwClients.GetRowCellValue(i, "clientno").ToString();
                            break;
                        }
                    }
                    Close();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void txtClient_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
            {
                //set the selected client as the current client and exit the window
                using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        for (int i = 0; i < vwClients.RowCount; i++)
                        {
                            if (vwClients.IsRowSelected(i))
                            {
                                ClassGenLib.selectedClient = vwClients.GetRowCellValue(i, "clientno").ToString();
                                break;
                            }
                        }
                        Close();
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("Error connecting to database! Reason:- " + ex.Message, "Falcon20", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
            else
            {
                ClientListing_Load(sender, e);
            }
        }

        private void vwClients_SelectionChanged(object sender, DevExpress.Data.SelectionChangedEventArgs e)
        {
            for(int i = 0; i < vwClients.RowCount; i++)
            {
                if(vwClients.IsRowSelected(i))
                {
                    lblName.Text = vwClients.GetRowCellValue(i, "clientname").ToString();
                    grpClient.Text = vwClients.GetRowCellValue(i, "category").ToString();
                    break;
                }
            }
        }

        private void vwClients_FocusedRowChanged(object sender, DevExpress.XtraGrid.Views.Base.FocusedRowChangedEventArgs e)
        {
            for (int i = 0; i < vwClients.RowCount; i++)
            {
                if (vwClients.IsRowSelected(i))
                {
                    lblName.Text = vwClients.GetRowCellValue(i, "clientname").ToString();
                    lblType.Text = vwClients.GetRowCellValue(i, "category").ToString();
                    lblAddress.Text = vwClients.GetRowCellValue(i, "physicaladdress").ToString();
                    lblPhone.Text = vwClients.GetRowCellValue(i, "contactno").ToString();
                    break;
                }
            }
        }
    }
}
