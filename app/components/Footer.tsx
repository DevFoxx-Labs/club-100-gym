"use client";

import React, { useState, useEffect } from 'react';
import { Dumbbell, MapPin, Phone, Globe, MessageSquare } from 'lucide-react';
import { motion } from 'framer-motion';
import { defaultGymInfo } from '@/lib/defaultContent';

interface FooterProps {
  onOpenBooking: () => void;
}

export default function Footer({ onOpenBooking }: FooterProps) {
  const [gymInfo, setGymInfo] = useState<any>(defaultGymInfo);

  useEffect(() => {
    fetch('/api/admin/content/gym-info')
      .then((res) => res.json())
      .then((data) => {
        if (data.success && data.data) {
          setGymInfo(data.data);
        }
      })
      .catch(() => {});
  }, []);

  const instagramUrl = gymInfo.instagramUrl || defaultGymInfo.instagramUrl || 'https://instagram.com';
  const facebookUrl = gymInfo.facebookUrl || defaultGymInfo.facebookUrl || 'https://facebook.com';
  const youtubeUrl = gymInfo.youtubeUrl || defaultGymInfo.youtubeUrl || 'https://youtube.com';
  const whatsappUrl = gymInfo.whatsappUrl || defaultGymInfo.whatsappUrl || 'https://wa.me/917084306574';

  return (
    <footer className="bg-[#08090c] text-slate-400 text-xs border-t border-[#1e222d] pt-16 pb-12 overflow-hidden">
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
        className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12"
      >
        
        {/* 4-Column Main Footer Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 text-left">
          
          {/* Col 1: Brand & Social */}
          <div className="space-y-4">
            <a href="#" className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-xl bg-[#b5f63d] text-[#0b0c10] flex items-center justify-center font-black">
                <Dumbbell className="w-4 h-4 fill-[#0b0c10]" />
              </div>
              <span className="text-lg sm:text-xl font-black text-white tracking-widest uppercase">
                {gymInfo.name || defaultGymInfo.name}
              </span>
            </a>
            <p className="text-xs text-slate-400 font-medium leading-relaxed">
              Health club with top-notch equipment & expert trainers. Caters to women too.
            </p>

            <div className="space-y-1 text-xs text-slate-400 pt-1 font-semibold">
              <p className="flex items-center gap-2">
                <MapPin className="w-3.5 h-3.5 text-[#b5f63d] shrink-0" /> {gymInfo.address ? gymInfo.address.split(',')[0] + ', Prayagraj' : 'TP Nagar, Transport Nagar, Prayagraj'}
              </p>
              <p className="flex items-center gap-2">
                <Phone className="w-3.5 h-3.5 text-[#b5f63d] shrink-0" /> {gymInfo.phone || defaultGymInfo.phone}
              </p>
            </div>

            <div className="flex items-center gap-4 text-slate-300 pt-2">
              {/* Instagram */}
              <a href={instagramUrl} target="_blank" rel="noopener noreferrer" className="hover:text-[#b5f63d] transition-colors p-1" aria-label="Instagram">
                <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
              </a>
              {/* Facebook */}
              <a href={facebookUrl} target="_blank" rel="noopener noreferrer" className="hover:text-[#b5f63d] transition-colors p-1" aria-label="Facebook">
                <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
              </a>
              {/* YouTube */}
              <a href={youtubeUrl} target="_blank" rel="noopener noreferrer" className="hover:text-[#b5f63d] transition-colors p-1" aria-label="YouTube">
                <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg>
              </a>
              {/* WhatsApp */}
              <a href={whatsappUrl} target="_blank" rel="noopener noreferrer" className="hover:text-[#b5f63d] transition-colors p-1" aria-label="WhatsApp">
                <MessageSquare className="w-4 h-4" />
              </a>
              {/* Globe Website */}
              <a href="https://club-100-the-gym.grexa.site/" target="_blank" rel="noopener noreferrer" className="hover:text-[#b5f63d] transition-colors p-1" aria-label="Official Website">
                <Globe className="w-4 h-4" />
              </a>
            </div>
          </div>

          {/* Col 2: Quick Links */}
          <div className="space-y-3">
            <h4 className="text-xs font-black text-white uppercase tracking-wider">Quick Links</h4>
            <ul className="space-y-2 text-xs font-semibold">
              <li><a href="#home" className="hover:text-white transition-colors">Home</a></li>
              <li><a href="#services" className="hover:text-white transition-colors">Services</a></li>
              <li><a href="#pricing" className="hover:text-white transition-colors">Pricing</a></li>
              <li><a href="#about" className="hover:text-white transition-colors">About Us</a></li>
              <li><a href="#contact" className="hover:text-white transition-colors">Contact</a></li>
            </ul>
          </div>

          {/* Col 3: Services Offered */}
          <div className="space-y-3">
            <h4 className="text-xs font-black text-white uppercase tracking-wider">Services</h4>
            <ul className="space-y-2 text-xs font-semibold">
              <li><a href="#services" className="hover:text-white transition-colors">HIIT Exercise Classes</a></li>
              <li><a href="#services" className="hover:text-white transition-colors">Aerobics & Fitness</a></li>
              <li><a href="#services" className="hover:text-white transition-colors">Crossfit Conditioning</a></li>
              <li><a href="#services" className="hover:text-white transition-colors">Personal Training</a></li>
              <li><a href="#services" className="hover:text-white transition-colors">Weight Training & Cycling</a></li>
            </ul>
          </div>

          {/* Col 4: Join Newsletter */}
          <div className="space-y-3">
            <h4 className="text-xs font-black text-white uppercase tracking-wider">Join Our Community</h4>
            <p className="text-xs text-slate-400 font-medium">Get fitness tips, offers, and batch updates.</p>

            <form onSubmit={(e) => e.preventDefault()} className="flex items-center gap-2 pt-1">
              <input
                type="email"
                placeholder="Your email"
                className="w-full p-2.5 rounded-full bg-[#13151b] border border-[#1e222d] text-xs text-white placeholder-slate-500 focus:outline-none focus:border-[#b5f63d]"
              />
              <button
                type="submit"
                onClick={onOpenBooking}
                className="btn-nova-neon px-4 py-2.5 text-xs rounded-full shrink-0 cursor-pointer"
              >
                Subscribe
              </button>
            </form>
          </div>

        </div>

        {/* Bottom Copyright Bar */}
        <div className="pt-8 border-t border-[#1e222d]/60 flex flex-col sm:flex-row items-center justify-between gap-4 text-[11px] text-slate-500 font-medium">
          <p>© {new Date().getFullYear()} Club 100 The Gym. All rights reserved.</p>

          <div className="flex flex-wrap items-center justify-center gap-4">
            <span>Transport Nagar, Prayagraj</span>
            <span className="text-slate-700">•</span>
            <span>4.8 ★ (230 Google Reviews)</span>
            <span className="text-slate-700">•</span>
            <span>
              Designed and Developed by{' '}
              <a
                href="http://devfoxxlabs.com"
                target="_blank"
                rel="noopener noreferrer"
                className="font-extrabold text-[#b5f63d] hover:underline"
              >
                DevFoxx Labs
              </a>
            </span>
            <span className="text-slate-700">•</span>
            <a href="/admin/login" className="hover:text-[#b5f63d] transition-colors font-semibold">
              Admin Portal
            </a>
          </div>
        </div>

      </motion.div>
    </footer>
  );
}
