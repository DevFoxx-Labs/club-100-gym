"use client";

import React, { useState, useRef } from 'react';
import { Activity, Flame, Zap, Target, BarChart2, Info, ArrowRight, Sliders } from 'lucide-react';
import { motion, useScroll, useTransform, useSpring } from 'framer-motion';

interface BmiCalculatorProps {
  onOpenBooking: () => void;
}

export default function BmiCalculator({ onOpenBooking }: BmiCalculatorProps) {
  const sectionRef = useRef<HTMLDivElement>(null);
  const [gender, setGender] = useState<'male' | 'female'>('male');
  const [goal, setGoal] = useState<'weight-loss' | 'muscle-gain' | 'maintenance'>('weight-loss');
  const [height, setHeight] = useState(175); // cm
  const [weight, setWeight] = useState(72);  // kg

  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"]
  });

  const bgY = useTransform(scrollYProgress, [0, 1], ["-10%", "10%"]);
  const smoothBgY = useSpring(bgY, { stiffness: 90, damping: 25 });

  // Calculate BMI
  const heightMeters = height / 100;
  const bmiNumber = weight / (heightMeters * heightMeters);
  const bmi = bmiNumber.toFixed(1);

  // Status & Range
  let statusLabel = 'Normal Weight';
  let statusBg = 'bg-[#10b981]/20 text-[#10b981] border-[#10b981]/40';
  let recProgram = 'Crossfit & Aerobics';

  if (bmiNumber < 18.5) {
    statusLabel = 'Underweight';
    statusBg = 'bg-[#38bdf8]/20 text-[#38bdf8] border-[#38bdf8]/40';
    recProgram = 'Weight Training & Muscle Gain';
  } else if (bmiNumber >= 25 && bmiNumber < 29.9) {
    statusLabel = 'Overweight';
    statusBg = 'bg-[#f59e0b]/20 text-[#f59e0b] border-[#f59e0b]/40';
    recProgram = 'HIIT & Weight Loss';
  } else if (bmiNumber >= 30) {
    statusLabel = 'Obese';
    statusBg = 'bg-[#ef4444]/20 text-[#ef4444] border-[#ef4444]/40';
    recProgram = 'Metabolic Conditioning & HIIT';
  }

  // Calculate Target Daily Calories (Mifflin-St Jeor Formula)
  const bmr = gender === 'male'
    ? 10 * weight + 6.25 * height - 5 * 25 + 5
    : 10 * weight + 6.25 * height - 5 * 25 - 161;

  let targetCalories = Math.round(bmr * 1.375);
  if (goal === 'weight-loss') targetCalories -= 350;
  if (goal === 'muscle-gain') targetCalories += 400;

  return (
    <section ref={sectionRef} id="calculator" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60 relative overflow-hidden min-h-[750px] flex items-center">
      
      {/* Full Section 3D Parallax Background Image */}
      <div className="absolute inset-0 pointer-events-none z-0 overflow-hidden">
        <motion.img
          style={{ y: smoothBgY }}
          src="/bmi_bg.png"
          alt="Club 100 BMI Background"
          className="w-full h-[125%] object-cover object-center opacity-85 -top-[12%] absolute"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-[#0b0c10]/70 via-[#0b0c10]/70 to-transparent z-10" />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0b0c10] via-transparent to-[#0b0c10]/85 z-10" />
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 w-full">

        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto space-y-3">
          <div className="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full bg-[#10b981]/15 text-[#10b981] border border-[#10b981]/30 text-xs font-black uppercase tracking-wider backdrop-blur-md">
            <Activity className="w-3.5 h-3.5" /> PERSONALIZED INSIGHTS
          </div>

          <h2 className="text-4xl sm:text-6xl font-black text-white tracking-tight">
            BMI & <span className="text-[#10b981]">Calorie</span> Calculator
          </h2>

          <p className="text-slate-300 text-xs sm:text-sm font-medium leading-relaxed max-w-xl mx-auto">
            Calculate your Body Mass Index and get a personalized daily calorie target to reach your fitness goals — in real time.
          </p>

          {/* 3 Feature Badges Row */}
          <div className="flex flex-wrap items-center justify-center gap-6 sm:gap-10 pt-3 text-xs">
            <div className="flex items-center gap-2 text-slate-300 font-bold">
              <Zap className="w-4 h-4 text-[#10b981]" />
              <div>
                <span className="block text-white font-black text-xs">Instant Results</span>
                <span className="text-[10px] text-slate-400 font-semibold">Real-time calculations</span>
              </div>
            </div>

            <div className="flex items-center gap-2 text-slate-300 font-bold">
              <Target className="w-4 h-4 text-[#10b981]" />
              <div>
                <span className="block text-white font-black text-xs">Personalized Goals</span>
                <span className="text-[10px] text-slate-400 font-semibold">Tailored to your needs</span>
              </div>
            </div>

            <div className="flex items-center gap-2 text-slate-300 font-bold">
              <BarChart2 className="w-4 h-4 text-[#10b981]" />
              <div>
                <span className="block text-white font-black text-xs">Smarter Progress</span>
                <span className="text-[10px] text-slate-400 font-semibold">Make better decisions</span>
              </div>
            </div>
          </div>
        </div>

        {/* Interactive Layout Grid */}
        <div className="grid lg:grid-cols-12 gap-8 mt-10 items-center">

          {/* Left Controls Card */}
          <div className="lg:col-span-7 bg-[#13151b]/90 backdrop-blur-xl rounded-3xl p-6 sm:p-8 border border-[#1e222d] space-y-6 shadow-2xl text-left">

            {/* Row 1: Gender & Goal */}
            <div className="grid sm:grid-cols-2 gap-4">
              {/* Gender */}
              <div className="space-y-2">
                <label className="block text-xs font-black text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                  <Sliders className="w-3.5 h-3.5 text-slate-400" /> Gender
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setGender('male')}
                    className={`py-3 rounded-xl border text-xs font-black transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
                      gender === 'male'
                        ? 'bg-[#13151b] text-[#10b981] border-[#10b981] shadow-lg shadow-[#10b981]/10'
                        : 'bg-[#0b0c10]/80 text-slate-400 border-[#1e222d]'
                    }`}
                  >
                    ♂ Male
                  </button>
                  <button
                    type="button"
                    onClick={() => setGender('female')}
                    className={`py-3 rounded-xl border text-xs font-black transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
                      gender === 'female'
                        ? 'bg-[#13151b] text-[#10b981] border-[#10b981] shadow-lg shadow-[#10b981]/10'
                        : 'bg-[#0b0c10]/80 text-slate-400 border-[#1e222d]'
                    }`}
                  >
                    ♀ Female
                  </button>
                </div>
              </div>

              {/* Goal Dropdown */}
              <div className="space-y-2">
                <label className="block text-xs font-black text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                  <Target className="w-3.5 h-3.5 text-slate-400" /> Primary Fitness Goal
                </label>
                <select
                  value={goal}
                  onChange={(e) => setGoal(e.target.value as any)}
                  className="w-full p-3 rounded-xl bg-[#0b0c10]/80 border border-[#1e222d] font-bold text-white text-xs focus:outline-none focus:border-[#10b981]"
                >
                  <option value="weight-loss">🔥 Rapid Fat Loss & Cardio</option>
                  <option value="muscle-gain">💪 Muscle Building & Strength</option>
                  <option value="maintenance">⚡ Maintenance & Stamina</option>
                </select>
              </div>
            </div>

            {/* Row 2: Height Slider */}
            <div className="space-y-2 pt-2">
              <div className="flex justify-between items-center text-xs font-black">
                <span className="text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                  📏 Height
                </span>
                <span className="text-[#a3e635] text-sm font-black">
                  {height} cm <span className="text-[10px] text-slate-400 font-semibold">({(height / 30.48).toFixed(1)} ft)</span>
                </span>
              </div>
              <input
                type="range"
                min="120"
                max="220"
                value={height}
                onChange={(e) => setHeight(Number(e.target.value))}
                className="w-full h-2 bg-[#0b0c10] rounded-lg appearance-none cursor-pointer accent-[#a3e635]"
              />
              <div className="flex justify-between text-[10px] text-slate-500 font-bold">
                <span>120 cm</span>
                <span>220 cm</span>
              </div>
            </div>

            {/* Row 3: Weight Slider */}
            <div className="space-y-2 pt-2">
              <div className="flex justify-between items-center text-xs font-black">
                <span className="text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                  ⚖️ Weight
                </span>
                <span className="text-[#38bdf8] text-sm font-black">
                  {weight} kg <span className="text-[10px] text-slate-400 font-semibold">({(weight * 2.20462).toFixed(0)} lbs)</span>
                </span>
              </div>
              <input
                type="range"
                min="30"
                max="200"
                value={weight}
                onChange={(e) => setWeight(Number(e.target.value))}
                className="w-full h-2 bg-[#0b0c10] rounded-lg appearance-none cursor-pointer accent-[#38bdf8]"
              />
              <div className="flex justify-between text-[10px] text-slate-500 font-bold">
                <span>30 kg</span>
                <span>200 kg</span>
              </div>
            </div>

          </div>

          {/* Right Analytics Card */}
          <div className="lg:col-span-5 space-y-5 text-left">
            
            <div className="bg-[#13151b]/90 backdrop-blur-xl rounded-3xl p-6 border border-[#1e222d] shadow-2xl space-y-6">

              {/* Live BMI & Arc Meter */}
              <div className="flex items-center justify-between">
                <div className="space-y-1 text-left">
                  <span className="text-[11px] font-black text-slate-400 uppercase tracking-wider flex items-center gap-1">
                    📊 Your Live BMI Score
                  </span>
                  <div className="text-5xl font-black text-white tracking-tight">
                    {bmi}
                  </div>
                  <div className={`inline-block px-3 py-1 rounded-full text-[10px] font-black border ${statusBg}`}>
                    {statusLabel}
                  </div>
                </div>

                <div className="relative w-28 h-28 flex items-center justify-center">
                  <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
                    <path
                      className="text-slate-800"
                      strokeWidth="3.5"
                      stroke="currentColor"
                      fill="none"
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    />
                    <path
                      className="text-[#10b981]"
                      strokeDasharray="75, 100"
                      strokeWidth="3.5"
                      strokeLinecap="round"
                      stroke="currentColor"
                      fill="none"
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    />
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                    <Activity className="w-4 h-4 text-[#10b981] animate-pulse" />
                    <span className="text-[9px] font-black text-slate-300">Healthy</span>
                    <span className="text-[8px] font-bold text-slate-400">18.5 - 24.9</span>
                  </div>
                </div>
              </div>

              {/* Rows */}
              <div className="space-y-3 pt-4 border-t border-[#1e222d] text-xs font-bold text-left">
                <div className="flex justify-between items-center p-3 rounded-xl bg-[#0b0c10]/80">
                  <span className="text-slate-400 flex items-center gap-1.5">
                    🍽️ Target Daily Intake
                  </span>
                  <span className="text-[#10b981] font-black text-sm flex items-center gap-1">
                    {targetCalories} kcal / day <Info className="w-3 h-3 text-slate-500" />
                  </span>
                </div>

                <div className="flex justify-between items-center p-3 rounded-xl bg-[#0b0c10]/80">
                  <span className="text-slate-400 flex items-center gap-1.5">
                    🏋️ Recommended Program
                  </span>
                  <span className="text-[#38bdf8] font-black text-xs flex items-center gap-1">
                    {recProgram} <Info className="w-3 h-3 text-slate-500" />
                  </span>
                </div>
              </div>

              {/* Full Neon Button */}
              <div className="space-y-2">
                <button
                  onClick={onOpenBooking}
                  className="w-full py-4 rounded-full bg-[#b5f63d] text-[#0b0c10] font-black text-xs shadow-xl flex items-center justify-center gap-2 hover:scale-105 transition-transform cursor-pointer"
                >
                  Get My Personalized Plan <ArrowRight className="w-4 h-4" />
                </button>
                <p className="text-[10px] text-slate-400 font-semibold text-center">
                  It's free. Instant reference pass included.
                </p>
              </div>

            </div>

          </div>

        </div>

      </div>
    </section>
  );
}
