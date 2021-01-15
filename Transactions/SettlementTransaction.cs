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

namespace WindowsFormsApplication1
{
    public partial class SettlementTransaction : Form
    {
        public SettlementTransaction()
        {
            InitializeComponent();
        }

        private void dtDealDate_EditValueChanged(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    using(SqlDataAdapter da = new SqlDataAdapter("select * from vwSettlementDeals where dealdate = '"+dtDealDate.Text+"' order by asset, qty", conn))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        grdTrades.DataSource = dt;
                    }

                    if (vwTrades.RowCount > 0)
                    {
                        //txtAmount.Text = String.Format("{0:0.0#}", Convert.ToDouble(vwTrades.GetRowCellValue(0, "settleamount").ToString()));
                        txtSum.Text = String.Format("{0:0.0#}", Convert.ToDouble(vwTrades.GetRowCellValue(0, "settleamount").ToString()));
                    }
                    else
                    {
                        txtAmount.Text = "0.00";
                        txtSum.Text = "0.00";
                    }
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Error connecting to database! " + ex.Message);
                }
            }
        }

        private void Form1_Load(object sender, EventArgs e)
        {

        }

        private void vwTrades_SelectionChanged(object sender, DevExpress.Data.SelectionChangedEventArgs e)
        {
            Double sumtotal = 0;

            if (txtSum.Text == "")
                txtSum.Text = "0";

            for(int i = 0; i < vwTrades.RowCount; i++)
            {
                if(vwTrades.IsRowSelected(i))
                {
                    sumtotal += Convert.ToDouble(vwTrades.GetRowCellValue(i, "settleamount").ToString());
                }
            }


            txtSum.Text = String.Format("{0:0.0#}", sumtotal.ToString()); ;
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            if(txtAmount.Text != txtSum.Text)
            {
                MessageBox.Show("Different amounts!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spSaveSettlement", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@settledate", dtDealDate.DateTime.Date);
                    SqlParameter p2 = new SqlParameter("@amount", txtSum.Text);

                    cmd.Parameters.Add(p1);
                    cmd.Parameters.Add(p2);
                    //cmd.ExecuteNonQuery();

                    txtSum.Text = ""; txtAmount.Text = "";

                    //grdTrades.DataSource = null;
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Failed to connect to database! "+ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            Close();
        }
    }
}
