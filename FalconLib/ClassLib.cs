using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace FalconLib
{
    public class ClassLib
    {
        public static float CalculateConsideration(float Qty,float Price)
        {
            {
                float PriceInDollars = Price / 100;
                return(Qty*PriceInDollars);//result will be in dollars
            }
        }

        public static float CalculateCommission(float Consideration, float Rate)
        {
            {
                float RateAsPercentage = Rate / 100;
                return (Consideration * RateAsPercentage);
            }
        }

        public static float CalculateVAT(float Amount, float Rate)
        {
            {
                float VATAsPercentage = Rate / 100;
                return (Amount * VATAsPercentage);
            }
        }

        public static float CalculateStampDuty(float Consideration, float Rate)
        {
            {
                float StampDutyAsPercentage = Rate / 100;
                return (Consideration * StampDutyAsPercentage);
            }
        }

        public static float CalculateCapitalGains(float Consideration, float Rate)
        {
            {
                float CapitalGainsAsPercentage = Rate / 100;
                return (Consideration * CapitalGainsAsPercentage);
            }
        }

        public static float CalculateInvestorProtection(float Consideration, float Rate)
        {
            {
                float InvestorProtectionAsPercentage = Rate / 100;
                return (Consideration * InvestorProtectionAsPercentage);
            }
        }

        public static float CalculateZSELevy(float Consideration, float Rate)
        {
            {
                float ZSELevyAsPercentage = Rate / 100;
                return (Consideration * ZSELevyAsPercentage);
            }
        }

        public static float CalculateSecLevy(float Consideration, float Rate)
        {
            {
                float SecLevyAsPercentage = Rate / 100;
                return (Consideration * SecLevyAsPercentage);
            }
        }
    }
}
