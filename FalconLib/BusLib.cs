using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

using System.Net.Mail;
using System.Net.NetworkInformation;
using System.Data.SqlClient;
using DBUtils;
using System.Data;


namespace FalconLib
{
    public class BusLib

    {
        public static string Username; //Variable receives the currently logged in user and is accessed by all other classes 
        public static string FromAdd;
        public static string Proxy;
        public static string SupportEmail;
        public static string Broker;
        public static string BrokerName;
        public static DateTime LockDate;
        public static bool LockedPeriod;
        public static DateTime FirstDayOfMonth;

        //public static DateTime DateToday;

        public static bool TimeoutUsers(string username, bool timeout, string window)
        {
            return false;
        }

        public static bool IsDealScripSettled(string dealno)
        {
            return false;
        }

        public static bool IsNumeric(string Text)
        {
            try
            {
                long result = long.Parse(Text);
                return true;
            }
            catch
            {
                return false;
            }
        }

        public static bool IsPeriodLocked(DateTime TransDate)
        {
            try
            {
                using (SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    Conn.Open();
                    SqlCommand cmd = new SqlCommand("select lockdate from systemparams",Conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    if (rd.Read())
                    {
                        if (rd["lockdate"].ToString() == "")
                            return false;
                        else if (TransDate <= Convert.ToDateTime(rd["lockdate"].ToString()))
                            return true;
                    }
                    return false;
                }
            }
            catch (Exception ex)
            {
                ex.ToString();
                return true;

            }
        }

              
        public static double CalculateConsideration(double Qty,double Price)
        {
            {
                double PriceInDollars = Price / 100;
                return(Qty*PriceInDollars);//result will be in dollars
            }
        }

        public static double CalculateCommission(double Consideration, double Rate)
        {
            {
                double RateAsPercentage = Rate / 100;
                return (Consideration * RateAsPercentage);
            }
        }

        public static double CalculateVAT(double Amount, double Rate)
        {
            {
                double VATAsPercentage = Rate / 100;
                return (Amount * VATAsPercentage);
            }
        }

        public static double CalculateStampDuty(double Consideration, double Rate)
        {
            {
                double StampDutyAsPercentage = Rate / 100;
                return (Consideration * StampDutyAsPercentage);
            }
        }

        public static double CalculateCapitalGains(double Consideration, double Rate)
        {
            {
                double CapitalGainsAsPercentage = Rate / 100;
                return (Consideration * CapitalGainsAsPercentage);
            }
        }

        public static double CalculateInvestorProtection(double Consideration, double Rate)
        {
            {
                double InvestorProtectionAsPercentage = Rate / 100;
                return (Consideration * InvestorProtectionAsPercentage);
            }
        }

        public static double CalculateZSELevy(double Consideration, double Rate)
        {
            {
                double ZSELevyAsPercentage = Rate / 100;
                return (Consideration * ZSELevyAsPercentage);
            }
        }

        public static double CalculateSecLevy(double Consideration, double Rate)
        {
            {
                double SecLevyAsPercentage = Rate / 100;
                return (Consideration * SecLevyAsPercentage);
            }
        }

        //CalculateCSDLevy added 17 July by G.Mhlanga

        public static double CalculateCSDLevy(double Consideration, double Rate)
        {
            {
                double CSDLevyAsPercentage = Rate / 100;
                return (Consideration * CSDLevyAsPercentage);
            }
        }

        public static bool SendEmail(string FromAdd, string ToAdd, string Subject, string BodyText,string Attachment )
        {
            //try
            //{
                
                MailMessage msg = new MailMessage(FromAdd, ToAdd, Subject, BodyText);
                msg.Attachments.Add(new Attachment(Attachment));
                SmtpClient client = new SmtpClient(Proxy);
                client.UseDefaultCredentials = true;
                client.Send(msg);
                msg.Dispose();
                   return true;
            //}
            //catch (Exception ex)
            //{
                
            //    return false;
            //}            
        }

        

        public static string ProperCase(string stringInput)
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            bool fEmptyBefore = true;
            foreach (char ch in stringInput)
            {
                char chThis = ch;
                if (Char.IsWhiteSpace(chThis))
                    fEmptyBefore = true;
                else
                {
                    if (Char.IsLetter(chThis) && fEmptyBefore)
                        chThis = Char.ToUpper(chThis);
                    else
                        chThis = Char.ToLower(chThis);
                    fEmptyBefore = false;
                }
                sb.Append(chThis);
            }
            return sb.ToString();
        }

        public static bool HasAccess(string CurrentUser,string Process) 
        {
            using (SqlConnection Conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                Conn.Open();
                SqlCommand cmdAccess = new SqlCommand("spCheckAccess", Conn);
                cmdAccess.CommandType = CommandType.StoredProcedure;
                SqlParameter param1 = new SqlParameter("@username", CurrentUser);
                SqlParameter param2 = new SqlParameter("@function", Process);
                cmdAccess.Parameters.Add(param1);
                cmdAccess.Parameters.Add(param2);

                int access = Convert.ToInt32(cmdAccess.ExecuteScalar());
                bool allowed = false;
                if (access == 1)
                    allowed = true;
                return allowed;
            }
        }

    }
}
