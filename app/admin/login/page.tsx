"use client";

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Dumbbell, Lock, User, Eye, EyeOff, ShieldCheck, ArrowRight, ArrowLeft, Database, AlertCircle, Sparkles } from 'lucide-react';
import { motion } from 'framer-motion';

export default function AdminLoginPage() {
  const router = useRouter();
  const [usernameOrEmail, setUsernameOrEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setErrorMsg('');
    setSuccessMsg('');

    try {
      const res = await fetch('/api/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ usernameOrEmail, password }),
      });

      const data = await res.json();

      if (data.success) {
        setSuccessMsg('Authentication successful! Redirecting to dashboard...');
        if (typeof window !== 'undefined') {
          localStorage.setItem('club100_admin_token', data.token);
          localStorage.setItem('club100_admin_user', JSON.stringify(data.user));
        }
        setTimeout(() => {
          router.push('/admin/dashboard');
        }, 800);
      } else {
        setErrorMsg(data.message || 'Invalid credentials.');
      }
    } catch (err: any) {
      setErrorMsg('Failed to connect to authentication server.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0b0c10] text-slate-100 flex flex-col justify-between relative overflow-hidden font-sans selection:bg-[#b5f63d] selection:text-[#0b0c10]">
      
      {/* Background Parallax Gym Ambience & Neon Glows */}
      <div className="absolute inset-0 pointer-events-none z-0 overflow-hidden">
        <img
          src="/gym_interior_neon.jpg"
          alt="Club 100 Dark Gym Background"
          className="w-full h-full object-cover opacity-25 object-center"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0b0c10] via-[#0b0c10]/85 to-[#0b0c10]" />
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[550px] h-[550px] bg-[#b5f63d]/10 rounded-full blur-[140px] pointer-events-none" />
      </div>

      {/* Top Bar Header */}
      <header className="relative z-10 max-w-7xl w-full mx-auto px-6 py-6 flex items-center justify-between">
        <a href="/" className="flex items-center gap-2 group">
          <div className="w-8 h-8 rounded-xl bg-[#b5f63d] text-[#0b0c10] flex items-center justify-center font-black group-hover:scale-110 transition-transform">
            <Dumbbell className="w-5 h-5 fill-[#0b0c10]" />
          </div>
          <span className="text-lg sm:text-xl font-black text-white tracking-widest uppercase">
            CLUB 100 <span className="text-[#b5f63d]">THE GYM</span>
          </span>
        </a>

        <a
          href="/"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#13151b] border border-[#1e222d] text-slate-300 hover:text-white hover:border-[#b5f63d] text-xs font-extrabold transition-all"
        >
          <ArrowLeft className="w-3.5 h-3.5 text-[#b5f63d]" /> Back to Main Site
        </a>
      </header>

      {/* Main Login Card Center */}
      <main className="relative z-10 max-w-md w-full mx-auto px-4 py-8 my-auto">
        <motion.div
          initial={{ opacity: 0, y: 30, scale: 0.96 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
          className="bg-[#13151b]/95 backdrop-blur-xl rounded-3xl p-8 border border-[#1e222d] hover:border-[#b5f63d]/40 shadow-2xl space-y-6 text-left"
        >
          
          {/* Card Top Title */}
          <div className="text-center space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#b5f63d]/15 text-[#b5f63d] border border-[#b5f63d]/30 text-xs font-black uppercase tracking-wider">
              <Database className="w-3.5 h-3.5" /> MONGODB POWERED PORTAL
            </div>

            <h1 className="text-3xl font-black text-white tracking-tight pt-1">
              Admin Portal Sign In
            </h1>
            <p className="text-xs text-slate-400 font-medium">
              Manage Club 100 inquiries, members, and batch schedules.
            </p>
          </div>

          {/* Error / Success Notifications */}
          {errorMsg && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="p-3.5 rounded-xl bg-red-500/15 border border-red-500/30 text-red-400 text-xs font-bold flex items-center gap-2.5"
            >
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </motion.div>
          )}

          {successMsg && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="p-3.5 rounded-xl bg-[#10b981]/15 border border-[#10b981]/30 text-[#10b981] text-xs font-bold flex items-center gap-2.5"
            >
              <ShieldCheck className="w-4 h-4 shrink-0" />
              <span>{successMsg}</span>
            </motion.div>
          )}

          {/* Login Form */}
          <form onSubmit={handleLogin} className="space-y-4">
            
            {/* Username / Email Field */}
            <div className="space-y-1.5">
              <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                <User className="w-3.5 h-3.5 text-[#b5f63d]" /> Username or Email
              </label>
              <div className="relative">
                <input
                  type="text"
                  required
                  placeholder="admin@club100.com or admin"
                  value={usernameOrEmail}
                  onChange={(e) => setUsernameOrEmail(e.target.value)}
                  className="w-full p-3.5 pl-4 rounded-xl border border-[#1e222d] bg-[#0b0c10] text-white text-xs sm:text-sm font-semibold placeholder-slate-500 focus:outline-none focus:border-[#b5f63d] focus:ring-1 focus:ring-[#b5f63d] transition-all"
                />
              </div>
            </div>

            {/* Password Field */}
            <div className="space-y-1.5">
              <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                <Lock className="w-3.5 h-3.5 text-[#b5f63d]" /> Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  required
                  placeholder="••••••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full p-3.5 pl-4 pr-10 rounded-xl border border-[#1e222d] bg-[#0b0c10] text-white text-xs sm:text-sm font-semibold placeholder-slate-500 focus:outline-none focus:border-[#b5f63d] focus:ring-1 focus:ring-[#b5f63d] transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white p-1 cursor-pointer"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              disabled={isLoading}
              type="submit"
              className="w-full py-4 rounded-2xl btn-nova-neon text-[#0b0c10] font-black text-sm shadow-xl flex items-center justify-center gap-2 cursor-pointer pt-3 mt-2 disabled:opacity-70"
            >
              {isLoading ? (
                <span>Authenticating with MongoDB...</span>
              ) : (
                <>
                  Sign In to Admin Portal <ArrowRight className="w-4 h-4 stroke-[2.5]" />
                </>
              )}
            </motion.button>

          </form>

          {/* Quick Testing Hint Box */}
          <div className="p-3.5 rounded-2xl bg-[#0b0c10] border border-[#1e222d] text-left text-[11px] space-y-1 font-medium">
            <span className="font-extrabold text-[#b5f63d] uppercase block">💡 Quick Login Demo Credentials:</span>
            <p className="text-slate-400">
              Username: <code className="text-white font-mono bg-[#13151b] px-1.5 py-0.5 rounded">admin</code> | Password: <code className="text-white font-mono bg-[#13151b] px-1.5 py-0.5 rounded">admin123</code>
            </p>
          </div>

        </motion.div>
      </main>

      {/* Footer copyright */}
      <footer className="relative z-10 text-center py-6 text-[11px] text-slate-500 font-medium">
        <p>© {new Date().getFullYear()} Club 100 The Gym • Transport Nagar, Prayagraj</p>
      </footer>

    </div>
  );
}
