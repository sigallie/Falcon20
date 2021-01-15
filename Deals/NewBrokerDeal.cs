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

namespace Deals
{
    public partial class NewBrokerDeal : Form
    {
        public NewBrokerDeal()
        {
            InitializeComponent();
        }

        private void NewBrokerDeal_Load(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string strSQL = "select companyname, clientno from clients where category = 'BROKER' order by companyname";
                    using(SqlDataAdapter da = new SqlDataAdapter(strSQL, conn))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        grdCounterparty.DataSource = dt;
                    }

                    strSQL = "select assetcode+' - '+assetname from assets order by assetcode";
                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    while(rd.Read())
                    {
                        cmbAsset.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason - " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                }
            }
        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            string clientno = "";
            for (int i = 0; i < vwCounterparty.RowCount; i++)
            {
                if(vwCounterparty.IsRowSelected(i))
                {
                    clientno = vwCounterparty.GetRowCellValue(i, "clientno").ToString();
                    break;
                }
            }

                using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();

                        string DealType = "";

                        if (rdoBuy.Checked == true)
                            DealType = "BUY";
                        if (rdoSell.Checked == true)
                            DealType = "SELL";

                        SqlCommand cmdPost = new SqlCommand("spPostDeal", conn);
                        cmdPost.CommandType = CommandType.StoredProcedure;
                        SqlParameter p1 = new SqlParameter("@dealdate", dtDealDate.Text);
                        SqlParameter p2 = new SqlParameter("@clientno", clientno);
                        SqlParameter p3 = new SqlParameter("@dealtype", DealType);
                        SqlParameter p4 = new SqlParameter("@qty", txtQty.Text);
                        SqlParameter p5 = new SqlParameter("@price", txtPrice.Text);
                        SqlParameter p6 = new SqlParameter("@asset", cmbAsset.Text);
                        SqlParameter p7 = new SqlParameter("@csdnumber", "");
                        SqlParameter p8 = new SqlParameter("@user", ClassGenLib.username);

                        cmdPost.Parameters.Add(p1); cmdPost.Parameters.Add(p2);
                        cmdPost.Parameters.Add(p3); cmdPost.Parameters.Add(p4);
                        cmdPost.Parameters.Add(p5); cmdPost.Parameters.Add(p6);
                        cmdPost.Parameters.Add(p7); cmdPost.Parameters.Add(p8);

                        cmdPost.ExecuteNonQuery();
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("Error connecting to database! Reason - " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    }
                }
        }
    }
}
