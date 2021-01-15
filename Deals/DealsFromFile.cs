using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.OleDb;
using System.IO;
using System.Data.SqlClient;

using LumenWorks.Framework.IO.Csv;

using DBUtils;
using GenLib;

namespace Deals
{
    public partial class DealsFromFile : Form
    {
        string ext = "";
        public DealsFromFile()
        {
            InitializeComponent();
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void buttonEdit1_ButtonClick(object sender, DevExpress.XtraEditors.Controls.ButtonPressedEventArgs e)
        {

        }

        public void ReadExcel(string fileName)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spPostDealFromFile", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@date", SqlDbType.VarChar);
                    SqlParameter p2 = new SqlParameter("@clientno", SqlDbType.VarChar);
                    SqlParameter p3 = new SqlParameter("@dealtype", SqlDbType.VarChar);
                    SqlParameter p4 = new SqlParameter("@qty", SqlDbType.Int);
                    SqlParameter p5 = new SqlParameter("@price", SqlDbType.Decimal);
                    SqlParameter p6 = new SqlParameter("@asset", SqlDbType.VarChar);
                    SqlParameter p7 = new SqlParameter("@csdnumber", SqlDbType.VarChar);
                    SqlParameter p8 = new SqlParameter("@user", ClassGenLib.username);
                    SqlParameter p9 = new SqlParameter("@noncustodial", true);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3);
                    cmd.Parameters.Add(p4); cmd.Parameters.Add(p5); cmd.Parameters.Add(p6);
                    cmd.Parameters.Add(p7); cmd.Parameters.Add(p8); cmd.Parameters.Add(p9);

                    string det = ""; string det1 = "";
                    var csvTable = new DataTable();
                    using (var csvReader = new CsvReader(new StreamReader(System.IO.File.OpenRead(@fileName)), true))
                    {
                        csvTable.Load(csvReader);
                        for (int i = 1; i < csvTable.Rows.Count; i++)
                        {
                            det = csvTable.Rows[i][15].ToString().Substring(0, 10);
                            det1 = det.Substring(6, 4) + "/" + det.Substring(0, 2) + "/" + det.Substring(3, 2);
                            p1.Value = Convert.ToDateTime(det1); // csvTable.Rows[i][15].ToString().Substring(0, 10);
                            p2.Value = csvTable.Rows[i][6].ToString();
                            p3.Value = csvTable.Rows[i][3].ToString().ToUpper();
                            p4.Value = csvTable.Rows[i][10].ToString().Replace(",","");
                            p5.Value = csvTable.Rows[i][9].ToString();
                            p6.Value = csvTable.Rows[i][2].ToString();
                            p7.Value = csvTable.Rows[i][6].ToString();

                            cmd.ExecuteNonQuery();
                        }
                    }
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Failed to coonect to database! " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }  
        private void simpleButton2_Click(object sender, EventArgs e)
        {
            if(txtFileName.Text != "")
            {
                string ext = Path.GetExtension(@txtFileName.Text);
                ReadExcel(txtFileName.Text);
                MessageBox.Show("Deals loaded successfully", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void txtFileName_ButtonClick(object sender, DevExpress.XtraEditors.Controls.ButtonPressedEventArgs e)
        {
            OpenFileDialog file = new OpenFileDialog(); //open dialog to choose file  
            //file.FileName
            if (file.ShowDialog() == System.Windows.Forms.DialogResult.OK) //if there is a file choosen by the user  
            {
              txtFileName.Text = file.FileName;
            }
        }
    }
}
