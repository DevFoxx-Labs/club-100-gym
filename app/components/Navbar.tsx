"use client";

import React, { useState } from 'react';
import { Menu, X, Phone, Dumbbell } from 'lucide-react';
import { motion } from 'framer-motion';

interface NavbarProps {
  onOpenBooking: () => void;
}

export default function Navbar({ onOpenBooking }: NavbarProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('Home');

  const navItems = ['Home', 'Services', 'About', 'Pricing', 'Reviews', 'Contact'];

  return (
    <header className="sticky top-0 z-50 w-full bg-[#0b0c10]/95 backdrop-blur-md border-b border-[#1e222d]/60">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
        
        {/* Brand Logo */}
        <a href="#" className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-xl bg-[#b5f63d] text-[#0b0c10] flex items-center justify-center font-black">
            <Dumbbell className="w-5 h-5 fill-[#0b0c10]" />
          </div>
          <span className="text-lg sm:text-xl font-black text-white tracking-widest uppercase">
            CLUB 100 <span className="text-[#b5f63d]">THE GYM</span>
          </span>
        </a>

        {/* Center Nav Links */}
        <nav className="hidden md:flex items-center gap-7 text-xs font-semibold text-slate-300">
          {navItems.map((item) => (
            <a
              key={item}
              href={`#${item.toLowerCase()}`}
              onClick={() => setActiveTab(item)}
              className={`relative py-1 transition-colors hover:text-white ${
                activeTab === item ? 'text-white font-bold' : 'text-slate-400'
              }`}
            >
              {item}
              {activeTab === item && (
                <motion.div
                  layoutId="activeTabIndicator"
                  className="absolute -bottom-1 left-0 right-0 h-0.5 bg-[#b5f63d] rounded-full"
                />
              )}
            </a>
          ))}
        </nav>

        {/* Right CTA Button */}
        <div className="hidden sm:flex items-center gap-4">
          <a
            href="tel:+917084306574"
            className="hidden lg:flex items-center gap-1.5 text-xs font-bold text-slate-400 hover:text-[#b5f63d] transition-colors"
          >
            <Phone className="w-3.5 h-3.5 text-[#b5f63d]" /> +91 70843 06574
          </a>
          <button
            onClick={onOpenBooking}
            className="btn-nova-neon px-6 py-2.5 text-xs cursor-pointer"
          >
            Join Now
          </button>
        </div>

        {/* Mobile Menu Trigger */}
        <div className="flex md:hidden items-center gap-2">
          <button
            onClick={onOpenBooking}
            className="btn-nova-neon px-4 py-1.5 text-xs sm:hidden cursor-pointer"
          >
            Join Now
          </button>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="p-2 text-slate-300 hover:text-white cursor-pointer"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-[#13151b] border-b border-[#1e222d] px-4 py-6 space-y-4 shadow-2xl">
          <div className="flex flex-col space-y-3 font-semibold text-slate-300 text-sm">
            {navItems.map((item) => (
              <a
                key={item}
                href={`#${item.toLowerCase()}`}
                onClick={() => { setActiveTab(item); setMobileMenuOpen(false); }}
                className="px-3 py-2 rounded-lg hover:bg-[#1e222d] hover:text-white transition-colors"
              >
                {item}
              </a>
            ))}
          </div>
          <div className="pt-2 border-t border-[#1e222d] space-y-2">
            <a
              href="tel:+917084306574"
              className="w-full py-2.5 rounded-xl bg-[#1e222d] text-white font-bold text-center text-xs flex items-center justify-center gap-2"
            >
              <Phone className="w-3.5 h-3.5 text-[#b5f63d]" /> +91 70843 06574
            </a>
            <button
              onClick={() => { setMobileMenuOpen(false); onOpenBooking(); }}
              className="w-full btn-nova-neon py-3 text-center text-xs cursor-pointer"
            >
              Join Now
            </button>
          </div>
        </div>
      )}
    </header>
  );
}
