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

namespace Clients
{
    public partial class NewClient : Form
    {
        string clientID;
        public NewClient(string id)
        {
            InitializeComponent();
            clientID = id;
        }

        private void btnNext1_Click(object sender, EventArgs e)
        {
            tbCompliance.PageVisible = true;
            tbPersonalInfo.PageVisible = false;
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            xtraTabControl1.TabPages[3].PageVisible = true;
            //tbClientName.PageVisible = false;
        }

        private void simpleButton4_Click(object sender, EventArgs e)
        {
            xtraTabControl1.TabPages[3].PageVisible = true;
            //tbCompanyName.PageVisible = false;
        }

        private void simpleButton2_Click(object sender, EventArgs e)
        {
            xtraTabControl1.TabPages[0].PageVisible = true;
            tbPersonalInfo.PageVisible = false;
        }

        private void simpleButton3_Click(object sender, EventArgs e)
        {
            xtraTabControl1.TabPages[0].PageVisible = true;
            //tbCompanyName.PageVisible = false;
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            
        }

        private void simpleButton11_Click(object sender, EventArgs e)
        {
            /*
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string clientType = "";
                    if (rdoIndividual.Checked == true)
                        clientType = "INDIVIDUAL";
                    if (rdoCompany.Checked == true)
                        clientType = "COMPANY";

                    SqlCommand cmd = new SqlCommand("spAddClient", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@clientno", "-1");
                    SqlParameter p2 = new SqlParameter("@companyname", txtCompanyName.Text);
                    SqlParameter p3 = new SqlParameter("@firstname", txtFirstname.Text);
                    SqlParameter p4 = new SqlParameter("@lastname", txtLastName.Text);
                    SqlParameter p5 = new SqlParameter("@address1", txtPhysicalAddress.Text);
                    SqlParameter p6 = new SqlParameter("@address2", txtPostalAddress.Text);
                    SqlParameter p7 = new SqlParameter("@city", txtCity.Text);
                    SqlParameter p8 = new SqlParameter("@country", txtCountry.Text);
                    SqlParameter p9 = new SqlParameter("@phone", txtPhone.Text);
                    SqlParameter p10 = new SqlParameter("@email", txtEmail.Text);
                    SqlParameter p11 = new SqlParameter("@contact", txtContactPerson.Text);
                    SqlParameter p12 = new SqlParameter("@type", clientType);
                    //SqlParameter p13 = new SqlParameter("@idno", txtLastName.Text);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.Parameters.Add(p5); cmd.Parameters.Add(p6); cmd.Parameters.Add(p7); cmd.Parameters.Add(p8);
                    cmd.Parameters.Add(p9); cmd.Parameters.Add(p10); cmd.Parameters.Add(p11); cmd.Parameters.Add(p12);
                    //cmd.Parameters.Add(p13); 

                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Client added successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);

                    txtCompanyName.Text = ""; txtFirstname.Text = ""; txtLastName.Text = ""; txtPhysicalAddress.Text = "";
                    txtPostalAddress.Text = ""; txtCity.Text = ""; txtCountry.Text = ""; txtPhone.Text = "";
                    txtEmail.Text = ""; txtContactPerson.Text = ""; txtLastName.Text = "";
                    for (int i = 0; i < xtraTabControl1.TabPages.Count; i++)
                        xtraTabControl1.TabPages[i].PageVisible = false;
                    xtraTabControl1.TabPages[0].PageVisible = true;
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }*/
        }

        private void NewClient_Load(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select clientcategory from clientcategory order by clientcategory", conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    while(rd.Read())
                    {
                        cmbCategory.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();

                    cmd.CommandText = "select sname from sector order by sname";
                    rd = cmd.ExecuteReader();

                    while(rd.Read())
                    {
                        cmbSector.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();

                    cmd.CommandText = "select [name] from banks order by [name]";
                    rd = cmd.ExecuteReader();

                    while (rd.Read())
                    {
                        cmbBankName.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();

                    if(clientID != "0")
                    {
                        //display the details of the selected client
                        SqlCommand cmdClient = new SqlCommand("select * from Clients where clientno = '"+clientID+"'", conn);
                        SqlDataReader rdClient = cmdClient.ExecuteReader();
                        while(rdClient.Read())
                        {
                            txtFirstname.Text = rdClient["FIRSTNAME"].ToString();
                            txtLastName.Text = rdClient["Surname"].ToString();
                            txtPhysicalAddress.Text = rdClient["PhysicalAddress"].ToString();
                            txtPostalAddress.Text = rdClient["POSTALADDRESS"].ToString();
                            cmbTitle.Text = rdClient["title"].ToString();
                            cmbGender.Text = rdClient["sex"].ToString();
                            txtClientNo.Text = rdClient["clientno"].ToString();
                            txtMobile.Text = rdClient["mobileno"].ToString();
                            txtPhone.Text = rdClient["contactno"].ToString();
                            cmbCategory.Text = rdClient["category"].ToString();
                            txtEmail.Text = rdClient["email"].ToString();
                            txtDirectors.Text = rdClient["directors"].ToString();
                            txtEmployer.Text = rdClient["employer"].ToString();
                            txtJobTitle.Text = rdClient["jobtitle"].ToString();
                            cmbSector.Text = rdClient["sector"].ToString();
                            txtBusPhone.Text = rdClient["busphone"].ToString();
                            txtContactPerson.Text = rdClient["contactperson"].ToString();
                            cmbBankName.Text = rdClient["bank"].ToString();
                            txtBranch.Text = rdClient["bankbranch"].ToString();
                            txtAccountNumber.Text = rdClient["bankaccountno"].ToString();
                            cmbAccountType.Text = rdClient["bankaccounttype"].ToString();
                            txtCSD.Text = rdClient["csdnumber"].ToString();
                        }
                        rdClient.Close();
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void simpleButton12_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void simpleButton7_Click(object sender, EventArgs e)
        {
            string company = ""; string surname = ""; string firstname = "";
            Boolean custodial = false;

            if(cmbCategory.Text == "")
            {
                MessageBox.Show("Client category has not been specified!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string clientType = "";
                    if (rdoIndividual.Checked == true)
                    {
                        clientType = "INDIVIDUAL";
                        surname = txtLastName.Text;
                        firstname = txtFirstname.Text;
                        company = "";
                    }
                    if (rdoCompany.Checked == true)
                    {
                        clientType = "COMPANY";
                        company = txtLastName.Text;
                        surname = "";
                        firstname = "";
                    }

                    if (rdoCustodial.Checked == true)
                        custodial = true;

                    SqlCommand cmd = new SqlCommand("spAddClient", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@clientno", clientID);
                    SqlParameter p2 = new SqlParameter("@companyname", company);
                    SqlParameter p3 = new SqlParameter("@firstname", firstname);
                    SqlParameter p4 = new SqlParameter("@lastname", surname);
                    SqlParameter p5 = new SqlParameter("@address1", txtPhysicalAddress.Text);
                    SqlParameter p6 = new SqlParameter("@address2", txtPostalAddress.Text);
                    SqlParameter p7 = new SqlParameter("@phone", txtPhone.Text);
                    SqlParameter p8 = new SqlParameter("@email", txtEmail.Text);
                    SqlParameter p9 = new SqlParameter("@contact", txtContactPerson.Text);
                    SqlParameter p10 = new SqlParameter("@type", clientType);
                    SqlParameter p11 = new SqlParameter("@bank", cmbBankName.Text);
                    SqlParameter p12 = new SqlParameter("@branch", txtBranch.Text);
                    SqlParameter p13 = new SqlParameter("@accountno", txtAccountNumber.Text);
                    SqlParameter p14 = new SqlParameter("@accounttype", cmbAccountType.Text);
                    SqlParameter p15 = new SqlParameter("@employer", txtEmployer.Text);
                    SqlParameter p16 = new SqlParameter("@sector", cmbSector.Text);
                    SqlParameter p17 = new SqlParameter("@jobtitle", txtJobTitle.Text);
                    SqlParameter p18 = new SqlParameter("@busphone", txtBusPhone.Text);
                    SqlParameter p19 = new SqlParameter("@title", cmbTitle.Text);
                    SqlParameter p20 = new SqlParameter("@category", cmbCategory.Text);
                    SqlParameter p21 = new SqlParameter("@custodial", 1);
                    SqlParameter p22 = new SqlParameter("@csdno", txtCSD.Text);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3); cmd.Parameters.Add(p4);
                    cmd.Parameters.Add(p5); cmd.Parameters.Add(p6); cmd.Parameters.Add(p7); cmd.Parameters.Add(p8);
                    cmd.Parameters.Add(p9); cmd.Parameters.Add(p10); cmd.Parameters.Add(p11); cmd.Parameters.Add(p12);
                    cmd.Parameters.Add(p13); cmd.Parameters.Add(p14); cmd.Parameters.Add(p15); cmd.Parameters.Add(p16);
                    cmd.Parameters.Add(p17); cmd.Parameters.Add(p18); cmd.Parameters.Add(p19); cmd.Parameters.Add(p20);
                    cmd.Parameters.Add(p21); cmd.Parameters.Add(p22);

                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Client added successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);

                    txtFirstname.Text = ""; txtLastName.Text = ""; txtPhysicalAddress.Text = "";
                    txtPostalAddress.Text = ""; txtPhone.Text = "";
                    txtEmail.Text = ""; txtContactPerson.Text = ""; txtLastName.Text = ""; txtPhone.Text = ""; txtBranch.Text = "";
                    txtBusPhone.Text = ""; txtAccountNumber.Text = ""; cmbAccountType.Text = ""; txtEmployer.Text = "";
                    cmbSector.Text = ""; txtJobTitle.Text = ""; cmbTitle.Text = ""; txtCSD.Text = "";

                    for (int i = 0; i < xtraTabControl1.TabPages.Count; i++)
                        xtraTabControl1.TabPages[i].PageVisible = false;
                    xtraTabControl1.TabPages[0].PageVisible = true;
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void simpleButton1_Click_1(object sender, EventArgs e)
        {
            Close();
        }

        private void simpleButton6_Click(object sender, EventArgs e)
        {
            tbCompliance.PageVisible = false;
            tbPersonalInfo.PageVisible = true;
        }

        private void rdoIndividual_Click(object sender, EventArgs e)
        {
            if (rdoIndividual.Checked == true)
            {
                lblSurnameCompany.Text = "Surname";
                txtFirstname.ReadOnly = false;
                cmbGender.ReadOnly = false;
                cmbTitle.ReadOnly = false;
                txtDirectors.ReadOnly = true; ;
            }
        }

        private void rdoCompany_Click(object sender, EventArgs e)
        {
            if (rdoCompany.Checked == true)
            {
                lblSurnameCompany.Text = "Company Name";
                txtFirstname.ReadOnly = true;
                cmbGender.ReadOnly = true;
                cmbTitle.ReadOnly = true;
                txtDirectors.ReadOnly = false;
            }
        }

        private void chkPostal_Click(object sender, EventArgs e)
        {
            if(chkPostal.Checked == true)
            {
                txtPostalAddress.Text = txtPhysicalAddress.Text;
            }
        }
    }
}
