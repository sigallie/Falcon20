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

namespace Admin
{
    public partial class SystemAdministration : Form
    {
        public SystemAdministration()
        {
            InitializeComponent();
        }

        private void LoadModules()
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                SqlCommand cmd = new SqlCommand("select * from modules order by modname", conn);
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    grdModule.DataSource = dt;
                }
            }
        }

        private void LoadBannedPasswords()
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                SqlCommand cmd = new SqlCommand("select * from bannedpasswords order by pass", conn);
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    grdAvoidPassword.DataSource = dt;
                }
            }
        }

        private void LoadBanks()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                SqlCommand cmd = new SqlCommand("select * from banks order by name", conn);
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    grdBank.DataSource = dt;
                }
            }
        }

        private void LoadClientCategory()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                SqlCommand cmd = new SqlCommand("select * from clientcategory order by clientcategory", conn);
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    grdCategory.DataSource = dt;
                }
            }
        }

        private void LoadCashbooks()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                SqlCommand cmd = new SqlCommand("select * from cashbooks order by code", conn);
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    grdCashbook.DataSource = dt;
                }
            }
        }

        private void LoadProfiles()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                SqlCommand cmd = new SqlCommand("select * from tblProfiles order by profilename", conn);
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    grdProfiles.DataSource = dt;
                }
            }
        }

        private void LoadAvailableFunctions()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                string strSQL = "select s.screenname, m.modname ";
                strSQL += "from tblscreens s inner join modules m on s.moduleid = m.mid ";
                strSQL += "order by m.modname, s.screenname";

                SqlCommand cmd = new SqlCommand(strSQL, conn);
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    grdAvailable.DataSource = dt;
                }
            }
        }

        private void LoadPermissions()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                string strSQL = "select p.profilename, s.screenname, m.modname ";
                strSQL += "	from tblpermissions p inner join tblscreens s on p.screen = s.id ";
                strSQL += "inner join modules m on p.moduleid = m.mid order by m.modname, s.screenname";

                SqlCommand cmd = new SqlCommand(strSQL, conn);
                using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                {
                    DataTable dt = new DataTable();
                    da.Fill(dt);

                    grdPermissions.DataSource = dt;
                }
            }
        }

        private void LoadQuestions()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    string strSQL = "select question ";
                    strSQL += "	from passquestions order by question ";

                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdQustion.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }
        private void LoadUserGroups()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    string strSQL = "select profilename ";
                    strSQL += "	from tblProfiles order by profilename ";

                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdGroups.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    //ScreenShot.EmailScreenShot(ex.ToString());
                }
            }
        }

        private void LoadModuleFunctions()
        {
            //get the selected module name
            string module = "";

            for(int i = 0; i < vwModule.RowCount; i++)
            {
                if(vwModule.IsRowSelected(i))
                {
                    module = vwModule.GetRowCellValue(i, "MODNAME").ToString();
                    break;
                }
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select mid from modules where modname = '"+ module +"'", conn);
                    int mid = Convert.ToInt32(cmd.ExecuteScalar());

                    cmd.CommandText = "select screenname from tblScreens where moduleid = " + mid.ToString() + " order by screenname";
                    using(SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdFunctions.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void LoadTransactionTypes()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    string strSQL = "select transtype, description, auto, credit, active ";
                    strSQL += "	from transtypes order by description ";

                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdTranstype.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    //ScreenShot.EmailScreenShot(ex.ToString());
                }
            }
        }

        private void LoadCompanyDetails()
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string strSQL = "select companyname, physicaladdress, companyinitials, postaladdress, phone, email, vatno, bpn ";
                    strSQL += "	from company ";

                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    while (rd.Read())
                    {
                        txtCompany.Text = rd[0].ToString();
                        txtAddress.Text = rd[1].ToString();
                        txtPostal.Text = rd[2].ToString();
                        txtPhone.Text = rd[3].ToString();
                        txtEmail.Text = rd[4].ToString();
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    //ScreenShot.EmailScreenShot(ex.ToString());
                }
            }
        }

        private void LoadHolidays()
        {
            //show the holidays

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select * from Holidays order by holidaydate desc", conn);
                    int mid = Convert.ToInt32(cmd.ExecuteScalar());

                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdHolidays.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void LoadBusinessRules()
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select * from BusinessRules", conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    while (rd.Read())
                    {
                        chkJournal.Checked = Convert.ToBoolean(rd["ApproveJournals"].ToString());
                        chkPayment.Checked = Convert.ToBoolean(rd["ApprovePayments"].ToString());
                        chkReceipt.Checked = Convert.ToBoolean(rd["ApproveReceipts"].ToString());
                    }
                    rd.Close();
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }
        private void SystemAdministration_Load(object sender, EventArgs e)
        {
            LoadClientCategory();
            LoadCashbooks();
            LoadBanks();
            LoadBannedPasswords();
            LoadProfiles();
            LoadAvailableFunctions();
            LoadPermissions();
            LoadUserGroups();
            LoadModules();
            LoadQuestions();
            LoadTransactionTypes();
            LoadCompanyDetails();
            LoadHolidays();
            LoadBusinessRules();
        }

        private void grdCategory_DoubleClick(object sender, EventArgs e)
        {
            
        }

        private void labelControl18_Click(object sender, EventArgs e)
        {

        }

        private void grdCategory_Click(object sender, EventArgs e)
        {
            for (int i = 0; i < vwCategory.RowCount; i++)
            {
                if (vwCategory.IsRowSelected(i))
                {
                    txtCategory.Text = vwCategory.GetRowCellValue(i, "ClientCategory").ToString();
                    txtCGT.Text = vwCategory.GetRowCellValue(i, "CapitalGains").ToString();
                    txtCLV.Text = vwCategory.GetRowCellValue(i, "CommissionerLevy").ToString();
                    txtCommission.Text = vwCategory.GetRowCellValue(i, "Commission").ToString();
                    txtCSD.Text = vwCategory.GetRowCellValue(i, "CSDLevy").ToString();
                    txtIPL.Text = vwCategory.GetRowCellValue(i, "InvestorProtection").ToString();
                    txtSD.Text = vwCategory.GetRowCellValue(i, "StampDuty").ToString();
                    txtVAT.Text = vwCategory.GetRowCellValue(i, "VAT").ToString();
                    txtZSE.Text = vwCategory.GetRowCellValue(i, "ZSELevy").ToString();
                }
            }
        }

        private void grdProfiles_Click(object sender, EventArgs e)
        {
            string userprofile = "";

            for(int i = 0; i < vwProfiles.RowCount; i++)
            {
                if(vwProfiles.IsRowSelected(i))
                {
                    userprofile = vwProfiles.GetRowCellValue(i, "profilename").ToString();
                    break;
                }
            }

            string strSQL = "select p.profilename, s.screenname, m.modname ";
            strSQL += "	from tblpermissions p inner join tblscreens s on p.screen = s.id ";
            strSQL += "inner join modules m on p.moduleid = m.mid ";
            strSQL += "where p.profilename = '" + userprofile + "' order by m.modname, s.screenname";

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand(strSQL, conn);

                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        grdPermissions.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    //ScreenShot.EmailScreenShot(ex.ToString());
                }
            }
        }

        private void btnAddPermission_Click(object sender, EventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "ASSIGN USER PERMISSION") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            //add a permission to a user group
            string profile = "";

            for(int i = 0; i < vwProfiles.RowCount; i++)
            {
                if(vwProfiles.IsRowSelected(i))
                {
                    profile = vwProfiles.GetRowCellValue(i, "profilename").ToString();
                    break;
                }
            }

            string module = ""; string function = "";
            for (int i = 0; i < vwAvailable.RowCount; i++)
            {
                if (vwAvailable.IsRowSelected(i))
                {
                    module = vwAvailable.GetRowCellValue(i, "modname").ToString();
                    function = vwAvailable.GetRowCellValue(i, "screenname").ToString(); 
                    break;
                }
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddUserPermission", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@profile", profile);
                    SqlParameter p2 = new SqlParameter("@module", module);
                    SqlParameter p3 = new SqlParameter("@function", function);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3);

                    cmd.ExecuteNonQuery();

                    grdProfiles_Click(sender, e);

                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    //ScreenShot.EmailScreenShot(ex.ToString());
                }
            }
        }

        private void btnRemovePermission_Click(object sender, EventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "REMOVE USER PERMISSION") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    string profile = ""; string module = ""; string function = "";

                    if(MessageBox.Show("Delete the selected permission?", "Falcon", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == System.Windows.Forms.DialogResult.Yes)
                    {
                        for(int i = 0; i < vwProfiles.RowCount; i++)
                        {
                            if(vwProfiles.IsRowSelected(i))
                            {
                                profile = vwProfiles.GetRowCellValue(i, "profilename").ToString();
                                break;
                            }
                        }
                        for(int i = 0; i < vwPermissions.RowCount; i++)
                        {
                            if (vwPermissions.IsRowSelected(i))
                            {
                                module = vwPermissions.GetRowCellValue(i, "modname").ToString();
                                function = vwPermissions.GetRowCellValue(i, "screenname").ToString();
                                break;
                            }
                        }

                        
                        SqlCommand cmd = new SqlCommand("spRemovePermission", conn);
                        cmd.CommandType = CommandType.StoredProcedure;

                        SqlParameter p1 = new SqlParameter("@profile", profile);
                        SqlParameter p2 = new SqlParameter("@module", module);
                        SqlParameter p3 = new SqlParameter("@function", function);

                        cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3); 
                        cmd.ExecuteNonQuery();

                        grdProfiles_Click(sender, e);

                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    //ScreenShot.EmailScreenShot(ex.ToString());
                }
            }
        }

        private void btnAdd_Click(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddRemoveBannedPassword", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@pass", txtAvoid.Text);
                    SqlParameter p2 = new SqlParameter("@code", 1);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                    cmd.ExecuteNonQuery();

                    LoadBannedPasswords();

                    txtAvoid.Text = "";
                }

                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    //ScreenShot.EmailScreenShot(ex.ToString());
                }
            }
        }

        private void removeTextToolStripMenuItem_Click(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    var pass = "";
                    for(int i = 0; i < vwAvoidPassword.RowCount; i++)
                    {
                        if(vwAvoidPassword.IsRowSelected(i))
                        {
                            pass = vwAvoidPassword.GetRowCellValue(i, "pass").ToString();
                            break;
                        }
                    }

                    SqlCommand cmd = new SqlCommand("spAddRemoveBannedPassword", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@pass", pass);
                    SqlParameter p2 = new SqlParameter("@code", 2);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                    cmd.ExecuteNonQuery();
                    LoadBannedPasswords();
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void simpleButton2_Click(object sender, EventArgs e)
        {
            if(txtCashbook.Text == "")
            {
                MessageBox.Show("Specify a cashbook!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddRemoveCashBook", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@cashbook", txtCashbook.Text);
                    SqlParameter p2 = new SqlParameter("@code", 1);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);

                    cmd.ExecuteNonQuery();
                    LoadCashbooks();

                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void vwCashbook_KeyUp(object sender, KeyEventArgs e)
        {
            
        }

        private void vwBank_KeyUp(object sender, KeyEventArgs e)
        {
            
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            if (txtBank.Text == "")
            {
                MessageBox.Show("Specify a bank!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddRemoveBank", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@bank", txtBank.Text);
                    SqlParameter p2 = new SqlParameter("@code", 1);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);

                    cmd.ExecuteNonQuery();
                    LoadBanks();

                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void addGroupToolStripMenuItem_Click(object sender, EventArgs e)
        {
            pnlGroup.Visible = true;
        }

        private void btnCancelGroup_Click(object sender, EventArgs e)
        {
            txtGroup.Text = "";
            pnlGroup.Visible = false;
        }

        private void btnAddGroup_Click(object sender, EventArgs e)
        {
            if(txtGroup.Text == "")
            {
                MessageBox.Show("Please specify the group name!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddRemoveUserGroup", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@group", txtGroup.Text);
                    SqlParameter p2 = new SqlParameter("@code", 1); ;

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                                                                                                                                                                                                                                      
                    cmd.ExecuteNonQuery();

                    LoadUserGroups();
                    txtGroup.Text = "";
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void grdGroups_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Delete)
            {
                using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        string groupname = "";

                        for(int i = 0; i < vwGroups.RowCount; i++)
                        {
                            if(vwGroups.IsRowSelected(i))
                            {
                                groupname = vwGroups.GetRowCellValue(i, "profilename").ToString();
                                break;
                            }
                        }

                        SqlCommand cmd = new SqlCommand("spDeleteUserGroup", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        SqlParameter p1 = new SqlParameter("@groupname", groupname);
                        cmd.Parameters.Add(p1);
                        cmd.ExecuteNonQuery();

                        LoadUserGroups();
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    }
                }
            }
        }

        private void grdAvoidPassword_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Delete)
            {
                using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        string groupname = "";

                        for (int i = 0; i < vwAvoidPassword.RowCount; i++)
                        {
                            if (vwAvoidPassword.IsRowSelected(i))
                            {
                                groupname = vwAvoidPassword.GetRowCellValue(i, "pass").ToString();
                                break;
                            }
                        }

                        SqlCommand cmd = new SqlCommand("spDeleteBannedPassword", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        SqlParameter p1 = new SqlParameter("@pass", groupname);
                        cmd.Parameters.Add(p1);
                        cmd.ExecuteNonQuery();

                        LoadBannedPasswords();
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    }
                }
            }
        }

        private void grdCashbook_KeyUp(object sender, KeyEventArgs e)
        {
            string cashbook = "";

            if (e.KeyCode == Keys.Delete)
            {
                for (int i = 0; i < vwCashbook.RowCount; i++)
                {
                    if (vwCashbook.IsRowSelected(i))
                    {
                        cashbook = vwCashbook.GetRowCellValue(i, "Code").ToString();
                        break;
                    }
                }


                using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        SqlCommand cmd = new SqlCommand("spAddRemoveCashbook", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        SqlParameter p1 = new SqlParameter("@cashbook", cashbook);
                        SqlParameter p2 = new SqlParameter("@code", 2);

                        cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                        cmd.ExecuteNonQuery();

                        LoadCashbooks();
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    }
                }
            }
            /*
             * 
            if (e.KeyCode == Keys.Delete)
            {
                string cashbook = "";

                for (int i = 0; i < vwCashbook.RowCount; i++)
                {
                    if (vwCashbook.IsRowSelected(i))
                    {
                        cashbook = vwCashbook.GetRowCellValue(i, "code").ToString();
                        break;
                    }

                    using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                    {
                        try
                        {
                            conn.Open();
                            SqlCommand cmd = new SqlCommand("spAddRemoveCashBook", conn);
                            cmd.CommandType = CommandType.StoredProcedure;

                            SqlParameter p1 = new SqlParameter("@cashbook", cashbook);
                            SqlParameter p2 = new SqlParameter("@code", 2);

                            cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);

                            cmd.ExecuteNonQuery();
                            LoadCashbooks();
                        }
                        catch (Exception ex)
                        {
                            MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                        }
                    }
                }
            }*/
        }

        private void grdBank_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Delete)
            {
                string bank = "";

                for (int i = 0; i < vwBank.RowCount; i++)
                {
                    if (vwBank.IsRowSelected(i))
                    {
                        bank = vwBank.GetRowCellValue(i, "Name").ToString();
                        break;
                    }
                }

                    using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                    {
                        try
                        {
                            conn.Open();
                            SqlCommand cmd = new SqlCommand("spAddRemoveBank", conn);
                            cmd.CommandType = CommandType.StoredProcedure;

                            SqlParameter p1 = new SqlParameter("@bank", bank);
                            SqlParameter p2 = new SqlParameter("@code", 2);

                            cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);

                            cmd.ExecuteNonQuery();
                            LoadBanks();
                        }
                        catch (Exception ex)
                        {
                            MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                        }
                    }
            }
        }

        private void grdModule_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Delete)
            {
                string module = "";

                for (int i = 0; i < vwModule.RowCount; i++)
                {
                    if (vwModule.IsRowSelected(i))
                    {
                        module = vwModule.GetRowCellValue(i, "MODNAME").ToString();
                        break;
                    }
                }

                    using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                    {
                        try
                        {
                            conn.Open();
                            SqlCommand cmd = new SqlCommand("spAddRemoveModule", conn);
                            cmd.CommandType = CommandType.StoredProcedure;

                            SqlParameter p1 = new SqlParameter("@module", module);
                            SqlParameter p2 = new SqlParameter("@code", 2);

                            cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);

                            cmd.ExecuteNonQuery();
                            LoadModules();
                        }
                        catch (Exception ex)
                        {
                            MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                        }
                    }
            }
            }

        private void btnCancelModule_Click(object sender, EventArgs e)
        {
            txtModule.Text = "";
            pnlModule.Visible = false;
        }

        private void vwModule_Click(object sender, EventArgs e)
        {
            //list the functions under the selected module
            int module = 0;

            for(int i = 0; i < vwModule.RowCount; i++)
            {
                if(vwModule.IsRowSelected(i))
                {
                    module = Convert.ToInt32(vwModule.GetRowCellValue(i, "MID").ToString());
                    break;
                }
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    
                    using(SqlDataAdapter da = new SqlDataAdapter("select screenname from tblScreens where moduleid = " + module.ToString(), conn))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        grdFunctions.DataSource = dt;
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void deleteModuleToolStripMenuItem_Click(object sender, EventArgs e)
        {
            pnlModule.Visible = true;
        }

        private void btnAddModule_Click(object sender, EventArgs e)
        {
            if(txtModule.Text == "")
            {
                MessageBox.Show("Specify the new module name!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddRemoveModule", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@module", txtModule.Text);
                    SqlParameter p2 = new SqlParameter("@code", 1);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);

                    cmd.ExecuteNonQuery();

                    LoadModules();
                    txtModule.Text = "";
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void addNewFunctionToolStripMenuItem_Click(object sender, EventArgs e)
        {
            pnlFunction.Visible = true;
        }

        private void btnAddFunction_Click(object sender, EventArgs e)
        {
            if(txtFunction.Text == "")
            {
                MessageBox.Show("Specify the new function!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();

                    string moduleName = "";

                    for(int i = 0; i < vwModule.RowCount; i++)
                    {
                        if(vwModule.IsRowSelected(i))
                        {
                            moduleName = vwModule.GetRowCellValue(i, "MODNAME").ToString();
                            break;
                        }
                    }

                    SqlCommand cmd = new SqlCommand("spAddRemoveModuleFunction", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@function", txtFunction.Text);
                    SqlParameter p2 = new SqlParameter("@module", moduleName);
                    SqlParameter p3 = new SqlParameter("@code", 1);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3);

                    cmd.ExecuteNonQuery();

                    LoadModuleFunctions();

                    txtFunction.Text = "";
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void btnCancelFunction_Click(object sender, EventArgs e)
        {
            txtFunction.Text = "";
            pnlFunction.Visible = false;
        }

        private void textEdit6_Properties_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Enter)
            {
                if(txtQuestion.Text == "")
                {
                    MessageBox.Show("Specify the question!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    return;
                }

                using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        SqlCommand cmd = new SqlCommand("spAddRemoveQuestion", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        SqlParameter p1 = new SqlParameter("@question", txtQuestion.Text);
                        SqlParameter p2 = new SqlParameter("@code", 1);

                        cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                        cmd.ExecuteNonQuery();

                        txtQuestion.Text = "";

                        LoadQuestions();
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    }
                }
            }
        }

        private void vwQuestion_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Delete)
            {
                string question = "";

                for (int i = 0; i < vwQuestion.RowCount; i++)
                {
                    if (vwQuestion.IsRowSelected(i))
                    {
                        question = vwQuestion.GetRowCellValue(i, "question").ToString();
                        break;
                    }
                }

                using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        SqlCommand cmd = new SqlCommand("spAddRemoveQuestion", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        SqlParameter p1 = new SqlParameter("@question", question);
                        SqlParameter p2 = new SqlParameter("@code", 2);

                        cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);
                        cmd.ExecuteNonQuery();

                        LoadQuestions();
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                    }
                }
            }
        }

        private void addNewTransactionTypeToolStripMenuItem_Click(object sender, EventArgs e)
        {
            NewTransType nType = new NewTransType();
            nType.ShowDialog();
        }

        private void deActivateTransTypeToolStripMenuItem_Click(object sender, EventArgs e)
        {
            string code = "";
            for (int i = 0; i < vwTranstype.RowCount; i++)
            {
                if (vwTranstype.IsRowSelected(i))
                {
                    code = vwTranstype.GetRowCellValue(i, "transtype").ToString();
                    break;
                }
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spDeactivateTransType", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@code", code);

                    cmd.Parameters.Add(p1);
                    cmd.ExecuteNonQuery();

                    LoadTransactionTypes();
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void btnCancelHoliday_Click(object sender, EventArgs e)
        {

        }

        private void btnSaveHoliday_Click(object sender, EventArgs e)
        {
            if(dtDate.Text == "" || txtHoliday.Text == "")
            {
                MessageBox.Show("Specify all the details!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddHoliday", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@date", dtDate.DateTime.Date);
                    SqlParameter p2 = new SqlParameter("@description", txtHoliday.Text);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2);

                    cmd.ExecuteNonQuery();

                    dtDate.Text = "";
                    txtHoliday.Text = "";
                    LoadHolidays();
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void vwHolidays_KeyUp(object sender, KeyEventArgs e)
        {
            if(e.KeyCode == Keys.Enter)
            {
                if(MessageBox.Show("Remove the selected holday(s)?", "Falcon", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == System.Windows.Forms.DialogResult.Yes)
                {
                    using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                    {
                        try
                        {
                            conn.Open();
                            SqlCommand cmd = new SqlCommand();
                            cmd.Connection = conn;

                            for(int i = 0; i < vwHolidays.RowCount; i++)
                            {
                                if(vwHolidays.IsRowSelected(i))
                                {
                                    cmd.CommandText = "delete from Holidays where id = " + vwHolidays.GetRowCellValue(i, "id").ToString();
                                    cmd.ExecuteNonQuery();
                                }
                            }

                            LoadHolidays();
                        }
                        catch (Exception ex)
                        {
                            MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                        }
                    }
                }
            }
        }

        private void tbBanks_Paint(object sender, PaintEventArgs e)
        {

        }

        private void btnSaveTransSetting_Click(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string strSQL = "update BusinessRules set ApproveReceipts = " + Convert.ToInt16(chkReceipt.Checked).ToString() + ", ApprovePayments = " + Convert.ToInt16(chkPayment.Checked).ToString() + ", ApproveJournals=" + Convert.ToInt16(chkJournal.Checked).ToString();
                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Transaction settings saved successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }
    }
}
