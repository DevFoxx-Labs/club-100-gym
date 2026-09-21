"use client";

import React, { useState, useEffect } from 'react';
import { Check } from 'lucide-react';
import { motion } from 'framer-motion';
import { defaultPlans } from '@/lib/defaultContent';

interface MembershipProps {
  onOpenBooking: () => void;
}

export default function Membership({ onOpenBooking }: MembershipProps) {
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [plans, setPlans] = useState<any[]>(defaultPlans);

  useEffect(() => {
    fetchPlans();
  }, []);

  const fetchPlans = async () => {
    try {
      const res = await fetch('/api/admin/content/plans');
      const data = await res.json();
      if (data.success && data.data && data.data.length > 0) {
        setPlans(data.data);
      }
    } catch (err) {
      console.warn('Using default fallback plans');
    }
  };

  return (
    <section id="pricing" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

        {/* Section Header with Right Toggle */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-14">
          <div className="space-y-2 text-left">
            <p className="text-xs sm:text-sm font-extrabold text-slate-400 tracking-[0.25em] uppercase">
              AFFORDABLE MEMBERSHIP PLANS
            </p>
            <h2 className="text-4xl sm:text-6xl font-black text-white tracking-tight">
              Simple. Flexible. Budget-Friendly.
            </h2>
          </div>

          {/* Toggle Switch */}
          <div className="inline-flex items-center p-1.5 rounded-full bg-[#13151b] border border-[#1e222d] self-start md:self-auto">
            <button
              onClick={() => setBillingCycle('monthly')}
              className={`px-5 py-2 rounded-full text-xs font-black transition-all cursor-pointer ${
                billingCycle === 'monthly'
                  ? 'bg-[#b5f63d] text-[#0b0c10] shadow-md'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              Monthly
            </button>
            <button
              onClick={() => setBillingCycle('yearly')}
              className={`px-5 py-2 rounded-full text-xs font-black transition-all cursor-pointer flex items-center gap-2 ${
                billingCycle === 'yearly'
                  ? 'bg-[#b5f63d] text-[#0b0c10] shadow-md'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              Yearly <span className="text-[10px] font-extrabold text-[#b5f63d]">Save 20%</span>
            </button>
          </div>
        </div>

        {/* 3 Pricing Cards */}
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          variants={{
            hidden: { opacity: 0 },
            visible: {
              opacity: 1,
              transition: { staggerChildren: 0.15 }
            }
          }}
          className="grid lg:grid-cols-3 gap-8 items-stretch text-left"
        >
          {plans.map((plan, idx) => {
            const displayPrice = billingCycle === 'monthly' ? (plan.monthlyPrice || plan.price) : (plan.yearlyPrice || plan.price);
            return (
              <motion.div
                key={plan._id || idx}
                variants={{
                  hidden: { opacity: 0, y: 35 },
                  visible: { opacity: 1, y: 0, transition: { duration: 0.7, ease: [0.16, 1, 0.3, 1] } }
                }}
                whileHover={{ y: -10, boxShadow: plan.popular ? "0px 15px 35px rgba(181,246,61,0.25)" : "0px 15px 35px rgba(0,0,0,0.6)" }}
                className={`relative rounded-3xl p-8 flex flex-col justify-between transition-all ${
                  plan.popular
                    ? 'card-nova-featured'
                    : 'card-nova'
                }`}
              >
                {plan.badge && (
                  <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full bg-[#13151b] border border-[#b5f63d] text-[#b5f63d] text-[11px] font-black uppercase tracking-wider shadow-lg">
                    {plan.badge}
                  </div>
                )}

                <div className="space-y-6">
                  <div>
                    <h3 className="text-2xl font-black text-white">{plan.name}</h3>
                    <div className="flex items-baseline gap-1 pt-3">
                      <span className="text-5xl font-black text-white tracking-tight">{displayPrice}</span>
                      <span className="text-xs text-slate-400 font-bold">{plan.period || '/month'}</span>
                    </div>
                  </div>

                  <div className="space-y-4 pt-4 border-t border-[#1e222d]">
                    {plan.features?.map((feat: string, fIdx: number) => (
                      <div key={fIdx} className="flex items-center gap-3 text-xs font-semibold text-slate-300">
                        <Check className="w-4 h-4 text-[#b5f63d] shrink-0" />
                        <span>{feat}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Get Started Button */}
                <div className="pt-8">
                  <motion.button
                    whileHover={{ scale: 1.03 }}
                    whileTap={{ scale: 0.97 }}
                    onClick={onOpenBooking}
                    className={`w-full py-3.5 rounded-full font-black text-xs transition-all cursor-pointer shadow-md ${
                      plan.popular
                        ? 'btn-nova-neon'
                        : 'border border-slate-700 bg-[#0b0c10] hover:bg-[#1e222d] text-white'
                    }`}
                  >
                    Get Started
                  </motion.button>
                </div>

              </motion.div>
            );
          })}
        </motion.div>

      </div>
    </section>
  );
}
