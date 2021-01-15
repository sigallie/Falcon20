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
using DevExpress.XtraGrid.Views.Card;

using DBUtils;
using GenLib;

namespace Transactions
{
    public partial class OnscreenTB : Form
    {
        public OnscreenTB()
        {
            InitializeComponent();
        }

        private void OnscreenTB_Load(object sender, EventArgs e)
        {
            dtpAsAt.EditValue = DateTime.Now;
            gridView1.ExpandAllGroups();
        }

        private void CreateTB()
        {
            try
            {
                using (SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    DateTime StatementDate = DateTime.Now;
                    DateTime StartDate = Convert.ToDateTime("01/01/2011");
                    DateTime EndDate = Convert.ToDateTime(dtpAsAt.Text);
                    Conn.Open();
                    SqlCommand cmd = new SqlCommand("AccountsTrialBalancePeriod @EndDate", Conn);
                    cmd.Parameters.AddWithValue("@EndDate", EndDate);
                    cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                //ScreenShot.EmailScreenShot(ex.ToString());
            }
        }

        private void CreateItemisedEntries()
        {
            //double Amt = double.Parse(txtAmount.Text);

            string CNo;
            int ClientNo;
            try
            {
                using (SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    //DateTime StatementDate = DateTime.Now;
                    DateTime StartDate = Convert.ToDateTime("01/01/2008");
                    DateTime EndDate = Convert.ToDateTime(dtpAsAt.Text);
                    Conn.Open();
                    for (ClientNo = 150; ClientNo <= 159; ClientNo++)
                    {
                        CNo = ClientNo.ToString();
                        SqlCommand cmd = new SqlCommand("PopulateTBItemised @Login,@ClientNo,@StartDate,@EndDate", Conn);
                        cmd.Parameters.AddWithValue("@Login", ClassGenLib.username);
                        cmd.Parameters.AddWithValue("@ClientNo", CNo);
                        cmd.Parameters.AddWithValue("@StartDate", StartDate);
                        cmd.Parameters.AddWithValue("@EndDate", EndDate);
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                //ScreenShot.EmailScreenShot(ex.ToString());
            }
        }

        private void LoadTB()
        {
            try
            {
                using (SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString))
                {

                    Conn.Open();
                    //Loading Payments
                    SqlDataAdapter da1 = new SqlDataAdapter("select * from trialbalancefinal", Conn);
                    //string str2 = "select distinct * from TBItemised";
                    string str2 = "Select clientno, postdate, dealno, transdate, description, amount from TBItemised order by transdate, recid";
                    SqlDataAdapter da2 = new SqlDataAdapter(str2, Conn);

                    DataSet dsDetails = new DataSet();
                    da1.Fill(dsDetails, "TB");

                    da2.Fill(dsDetails, "TBItemised");

                    DataColumn keyColumn = dsDetails.Tables["TB"].Columns["ClientNo"];
                    DataColumn foreignKeyColumn = dsDetails.Tables["TBItemised"].Columns["ClientNo"];
                    dsDetails.Relations.Add("Itemised Entries", keyColumn, foreignKeyColumn);

                    grdTB.DataSource = dsDetails.Tables["TB"];
                    grdTB.ForceInitialize();

                    CardView cardView1 = new CardView(grdTB);
                    grdTB.LevelTree.Nodes.Add("Entries", cardView1);


                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                //ScreenShot.EmailScreenShot(ex.ToString());
            }
        }

        private void dtpAsAt_EditValueChanged(object sender, EventArgs e)
        {
            txtAsAt.Text = dtpAsAt.Text;
        }

        private void dtpAsAt_TextChanged(object sender, EventArgs e)
        {
            try
            {
                using (SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    Conn.Open();
                    SqlCommand delcmdtemp = new SqlCommand("truncate table tbitemisedtemp", Conn);
                    delcmdtemp.ExecuteNonQuery();

                    SqlCommand delcmd = new SqlCommand("truncate table tbitemised", Conn);
                    delcmd.ExecuteNonQuery();

                    CreateTB();
                    CreateItemisedEntries();
                    LoadTB();
                    //btnShowTB.Enabled = true;
                    gridView1.ExpandAllGroups();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                // btnShowTB.Enabled = true;
                //ScreenShot.EmailScreenShot(ex.ToString());
            }
        }
    }
}
