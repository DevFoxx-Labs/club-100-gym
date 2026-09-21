"use client";

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Dumbbell, Users, Database, Star, Phone, Clock, LogOut, RefreshCw, Plus, Search, Edit3, Trash2, CheckCircle2, Save, X, Layers, MapPin, Sparkles, Sliders } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

export default function AdminDashboardPage() {
  const router = useRouter();
  const [adminUser, setAdminUser] = useState<any>(null);
  const [activeTab, setActiveTab] = useState<'inquiries' | 'plans' | 'trainers' | 'services' | 'contact'>('inquiries');

  // Data states
  const [inquiries, setInquiries] = useState<any[]>([]);
  const [plans, setPlans] = useState<any[]>([]);
  const [trainers, setTrainers] = useState<any[]>([]);
  const [services, setServices] = useState<any[]>([]);
  const [gymInfo, setGymInfo] = useState<any>({});

  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusMsg, setStatusMsg] = useState('');

  // Modals for editing/creating items
  const [editModal, setEditModal] = useState<{
    type: 'plan' | 'trainer' | 'service' | null;
    item: any;
  }>({ type: null, item: null });

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const storedUser = localStorage.getItem('club100_admin_user');
      if (!storedUser) {
        router.push('/admin/login');
        return;
      }
      setAdminUser(JSON.parse(storedUser));
    }
    fetchAllData();
  }, [router]);

  const fetchAllData = async () => {
    setIsLoading(true);
    try {
      const [inqRes, planRes, trnRes, srvRes, infoRes] = await Promise.all([
        fetch('/api/admin/inquiries'),
        fetch('/api/admin/content/plans'),
        fetch('/api/admin/content/trainers'),
        fetch('/api/admin/content/services'),
        fetch('/api/admin/content/gym-info')
      ]);

      const [inqData, planData, trnData, srvData, infoData] = await Promise.all([
        inqRes.json(), planRes.json(), trnRes.json(), srvRes.json(), infoRes.json()
      ]);

      if (inqData.data) setInquiries(inqData.data);
      if (planData.data) setPlans(planData.data);
      if (trnData.data) setTrainers(trnData.data);
      if (srvData.data) setServices(srvData.data);
      if (infoData.data) setGymInfo(infoData.data);
    } catch (err) {
      console.error('Error fetching dashboard content:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleLogout = () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('club100_admin_token');
      localStorage.removeItem('club100_admin_user');
    }
    router.push('/admin/login');
  };

  // Plan CRUD
  const savePlan = async (e: React.FormEvent) => {
    e.preventDefault();
    const item = editModal.item;
    const method = item._id && !item._id.startsWith('plan-') ? 'PUT' : 'POST';

    const res = await fetch('/api/admin/content/plans', {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(item)
    });
    const data = await res.json();
    if (data.success) {
      setStatusMsg('Plan saved successfully!');
      setEditModal({ type: null, item: null });
      fetchAllData();
    }
  };

  const deletePlan = async (id: string) => {
    if (!confirm('Are you sure you want to delete this plan?')) return;
    await fetch(`/api/admin/content/plans?id=${id}`, { method: 'DELETE' });
    setStatusMsg('Plan deleted');
    fetchAllData();
  };

  // Trainer CRUD
  const saveTrainer = async (e: React.FormEvent) => {
    e.preventDefault();
    const item = editModal.item;
    const method = item._id && !item._id.startsWith('trn-') ? 'PUT' : 'POST';

    const res = await fetch('/api/admin/content/trainers', {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(item)
    });
    const data = await res.json();
    if (data.success) {
      setStatusMsg('Trainer saved successfully!');
      setEditModal({ type: null, item: null });
      fetchAllData();
    }
  };

  const deleteTrainer = async (id: string) => {
    if (!confirm('Are you sure you want to delete this trainer?')) return;
    await fetch(`/api/admin/content/trainers?id=${id}`, { method: 'DELETE' });
    setStatusMsg('Trainer deleted');
    fetchAllData();
  };

  // Service CRUD
  const saveService = async (e: React.FormEvent) => {
    e.preventDefault();
    const item = editModal.item;
    const method = item._id && !item._id.startsWith('srv-') ? 'PUT' : 'POST';

    const res = await fetch('/api/admin/content/services', {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(item)
    });
    const data = await res.json();
    if (data.success) {
      setStatusMsg('Service saved successfully!');
      setEditModal({ type: null, item: null });
      fetchAllData();
    }
  };

  const deleteService = async (id: string) => {
    if (!confirm('Are you sure you want to delete this service?')) return;
    await fetch(`/api/admin/content/services?id=${id}`, { method: 'DELETE' });
    setStatusMsg('Service deleted');
    fetchAllData();
  };

  // Gym Contact Info Save
  const saveGymInfo = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await fetch('/api/admin/content/gym-info', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(gymInfo)
    });
    const data = await res.json();
    if (data.success) {
      setStatusMsg('Gym contact details & info updated successfully!');
      fetchAllData();
    }
  };

  const filteredInquiries = inquiries.filter((inq) =>
    inq.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    inq.referenceId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    inq.phone?.includes(searchTerm)
  );

  return (
    <div className="min-h-screen bg-[#0b0c10] text-slate-100 flex flex-col justify-between font-sans selection:bg-[#b5f63d] selection:text-[#0b0c10]">
      
      {/* Admin Header */}
      <header className="sticky top-0 z-50 bg-[#0b0c10]/95 backdrop-blur-md border-b border-[#1e222d] px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-xl bg-[#b5f63d] text-[#0b0c10] flex items-center justify-center font-black">
              <Dumbbell className="w-5 h-5 fill-[#0b0c10]" />
            </div>
            <div>
              <span className="text-lg font-black text-white tracking-widest uppercase block">
                CLUB 100 <span className="text-[#b5f63d]">ADMIN MANAGEMENT</span>
              </span>
              <span className="text-[10px] text-slate-400 font-semibold block">Transport Nagar, Prayagraj</span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#13151b] border border-[#1e222d] text-xs font-bold">
              <Database className="w-3.5 h-3.5 text-[#b5f63d]" />
              <span className="text-slate-300">Logged:</span>
              <span className="text-[#b5f63d]">{adminUser?.username || 'Admin'}</span>
            </div>

            <button
              onClick={handleLogout}
              className="px-4 py-2 rounded-full bg-[#13151b] border border-[#1e222d] hover:border-red-500 text-slate-300 hover:text-red-400 text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5"
            >
              <LogOut className="w-3.5 h-3.5" /> Logout
            </button>
          </div>

        </div>
      </header>

      {/* Main Dashboard Body */}
      <main className="max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8 flex-1 text-left">
        
        {/* Top Header & Status Notification */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="space-y-1">
            <span className="text-xs font-black text-[#b5f63d] uppercase tracking-wider block">MongoDB Database Control Panel</span>
            <h1 className="text-3xl font-black text-white tracking-tight">Manage Landing Page & Inquiries</h1>
          </div>

          <button
            onClick={fetchAllData}
            className="px-4 py-2.5 rounded-full bg-[#13151b] border border-[#1e222d] hover:border-[#b5f63d] text-xs font-black text-white flex items-center gap-2 transition-all cursor-pointer self-start sm:self-auto"
          >
            <RefreshCw className={`w-3.5 h-3.5 text-[#b5f63d] ${isLoading ? 'animate-spin' : ''}`} /> Refresh All Data
          </button>
        </div>

        {statusMsg && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="p-3.5 rounded-xl bg-[#10b981]/15 border border-[#10b981]/30 text-[#10b981] text-xs font-bold flex items-center justify-between"
          >
            <span className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4" /> {statusMsg}</span>
            <button onClick={() => setStatusMsg('')} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
          </motion.div>
        )}

        {/* 5 Management Nav Tabs */}
        <div className="flex flex-wrap gap-2 border-b border-[#1e222d] pb-4">
          {[
            { id: 'inquiries', label: 'Pass Inquiries', icon: <Users className="w-4 h-4" />, count: inquiries.length },
            { id: 'plans', label: 'Membership Plans', icon: <Layers className="w-4 h-4" />, count: plans.length },
            { id: 'trainers', label: 'Trainers', icon: <Dumbbell className="w-4 h-4" />, count: trainers.length },
            { id: 'services', label: 'Services', icon: <Sparkles className="w-4 h-4" />, count: services.length },
            { id: 'contact', label: 'Contact & Gym Details', icon: <MapPin className="w-4 h-4" /> },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`px-5 py-2.5 rounded-2xl text-xs font-black transition-all cursor-pointer flex items-center gap-2 ${
                activeTab === tab.id
                  ? 'bg-[#b5f63d] text-[#0b0c10] shadow-lg shadow-[#b5f63d]/20'
                  : 'bg-[#13151b] border border-[#1e222d] text-slate-400 hover:text-white hover:border-slate-700'
              }`}
            >
              {tab.icon}
              {tab.label}
              {tab.count !== undefined && (
                <span className={`px-2 py-0.5 rounded-full text-[10px] ${activeTab === tab.id ? 'bg-[#0b0c10] text-[#b5f63d]' : 'bg-[#0b0c10] text-slate-300'}`}>
                  {tab.count}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* TAB 1: INQUIRIES */}
        {activeTab === 'inquiries' && (
          <div className="space-y-6">
            <div className="bg-[#13151b] p-4 rounded-2xl border border-[#1e222d] flex flex-col sm:flex-row items-center justify-between gap-4">
              <div className="relative w-full sm:w-80">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search inquiries by name, phone or ref..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs text-white placeholder-slate-500 focus:outline-none focus:border-[#b5f63d]"
                />
              </div>

              <span className="text-xs text-slate-400 font-medium">
                Showing <strong className="text-white">{filteredInquiries.length}</strong> inquiries
              </span>
            </div>

            <div className="bg-[#13151b] rounded-3xl border border-[#1e222d] overflow-hidden shadow-2xl">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs font-medium border-collapse">
                  <thead>
                    <tr className="bg-[#0b0c10] border-b border-[#1e222d] text-slate-400 uppercase text-[10px] tracking-wider">
                      <th className="p-4">Reference ID</th>
                      <th className="p-4">Applicant Name</th>
                      <th className="p-4">Phone Number</th>
                      <th className="p-4">Inquiry / Pass Type</th>
                      <th className="p-4">Program Service</th>
                      <th className="p-4">Batch Time</th>
                      <th className="p-4">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#1e222d]">
                    {isLoading ? (
                      <tr><td colSpan={7} className="p-8 text-center text-slate-400 font-bold">Loading inquiries from MongoDB...</td></tr>
                    ) : filteredInquiries.length === 0 ? (
                      <tr><td colSpan={7} className="p-8 text-center text-slate-400 font-bold">No inquiries found matching search.</td></tr>
                    ) : (
                      filteredInquiries.map((row, idx) => (
                        <tr key={row._id || idx} className="hover:bg-[#0b0c10]/60 transition-colors">
                          <td className="p-4 font-mono font-black text-[#b5f63d]">{row.referenceId}</td>
                          <td className="p-4 font-bold text-white">{row.name}</td>
                          <td className="p-4 text-slate-300 font-semibold">{row.phone}</td>
                          <td className="p-4">
                            <span className="px-2.5 py-1 rounded-full bg-[#0b0c10] border border-[#1e222d] text-slate-300 text-[10px] font-bold">
                              {row.passType}
                            </span>
                          </td>
                          <td className="p-4 font-bold text-[#38bdf8]">{row.program}</td>
                          <td className="p-4 text-slate-300">{row.timeSlot}</td>
                          <td className="p-4">
                            <span className="px-2.5 py-1 rounded-full bg-[#10b981]/15 text-[#10b981] border border-[#10b981]/30 text-[10px] font-black">
                              {row.status || 'Confirmed'}
                            </span>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: PLANS MANAGEMENT */}
        {activeTab === 'plans' && (
          <div className="space-y-6">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-black text-white">Manage Membership Plans</h2>
              <button
                onClick={() => setEditModal({
                  type: 'plan',
                  item: { name: '', monthlyPrice: '₹999', yearlyPrice: '₹799', period: '/month', popular: false, badge: '', features: ['Gym Access', 'Clean Equipment'] }
                })}
                className="btn-nova-neon px-5 py-2 text-xs font-black flex items-center gap-1.5 cursor-pointer"
              >
                <Plus className="w-4 h-4 stroke-[3]" /> Add New Plan
              </button>
            </div>

            <div className="grid lg:grid-cols-3 gap-6">
              {plans.map((p, idx) => (
                <div key={p._id || idx} className="bg-[#13151b] p-6 rounded-3xl border border-[#1e222d] space-y-4 text-left shadow-xl relative">
                  {p.badge && (
                    <span className="px-3 py-1 rounded-full bg-[#b5f63d]/20 text-[#b5f63d] text-[10px] font-black border border-[#b5f63d]/40 uppercase tracking-wider">
                      {p.badge}
                    </span>
                  )}
                  <h3 className="text-2xl font-black text-white">{p.name}</h3>
                  <div className="space-y-1">
                    <p className="text-sm font-bold text-[#b5f63d]">Monthly: {p.monthlyPrice}</p>
                    <p className="text-sm font-bold text-[#38bdf8]">Yearly: {p.yearlyPrice}</p>
                  </div>
                  <ul className="space-y-2 text-xs text-slate-300 font-semibold border-t border-[#1e222d] pt-3">
                    {p.features?.map((f: string, fIdx: number) => (
                      <li key={fIdx} className="flex items-center gap-2">✓ {f}</li>
                    ))}
                  </ul>
                  <div className="flex gap-2 pt-4 border-t border-[#1e222d]">
                    <button
                      onClick={() => setEditModal({ type: 'plan', item: { ...p } })}
                      className="w-full py-2 rounded-xl bg-[#0b0c10] border border-[#1e222d] hover:border-[#b5f63d] text-white font-bold text-xs flex items-center justify-center gap-1.5 cursor-pointer"
                    >
                      <Edit3 className="w-3.5 h-3.5 text-[#b5f63d]" /> Edit
                    </button>
                    <button
                      onClick={() => deletePlan(p._id)}
                      className="py-2 px-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] hover:border-red-500 text-slate-400 hover:text-red-400 text-xs font-bold cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 3: TRAINERS MANAGEMENT */}
        {activeTab === 'trainers' && (
          <div className="space-y-6">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-black text-white">Manage Expert Trainers</h2>
              <button
                onClick={() => setEditModal({
                  type: 'trainer',
                  item: { name: '', category: 'Strength Coach', specialties: 'HIIT • Strength', description: 'Expert trainer', fullBio: 'Bio details', experience: '5+ Years', certifications: ['Certified Trainer'], rating: 4.8, isTopRated: false, image: '/trainer_hero.jpg' }
                })}
                className="btn-nova-neon px-5 py-2 text-xs font-black flex items-center gap-1.5 cursor-pointer"
              >
                <Plus className="w-4 h-4 stroke-[3]" /> Add New Trainer
              </button>
            </div>

            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {trainers.map((trn, idx) => (
                <div key={trn._id || idx} className="bg-[#13151b] p-4 rounded-3xl border border-[#1e222d] space-y-3 text-left shadow-xl relative flex flex-col justify-between">
                  <div className="relative h-48 rounded-2xl overflow-hidden bg-[#0b0c10]">
                    <img src={trn.image || '/trainer_hero.jpg'} alt={trn.name} className="w-full h-full object-cover object-top" />
                  </div>
                  <div>
                    <span className="text-[10px] font-black text-[#b5f63d] uppercase tracking-wider block">{trn.category}</span>
                    <h3 className="text-xl font-black text-white">{trn.name}</h3>
                    <p className="text-xs text-slate-400 font-semibold">{trn.experience} Exp • ★ {trn.rating}</p>
                    <p className="text-xs text-slate-300 font-medium line-clamp-2 pt-1">{trn.description}</p>
                  </div>
                  <div className="flex gap-2 pt-3 border-t border-[#1e222d]">
                    <button
                      onClick={() => setEditModal({ type: 'trainer', item: { ...trn } })}
                      className="w-full py-2 rounded-xl bg-[#0b0c10] border border-[#1e222d] hover:border-[#b5f63d] text-white font-bold text-xs flex items-center justify-center gap-1.5 cursor-pointer"
                    >
                      <Edit3 className="w-3.5 h-3.5 text-[#b5f63d]" /> Edit
                    </button>
                    <button
                      onClick={() => deleteTrainer(trn._id)}
                      className="py-2 px-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] hover:border-red-500 text-slate-400 hover:text-red-400 text-xs font-bold cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 4: SERVICES MANAGEMENT */}
        {activeTab === 'services' && (
          <div className="space-y-6">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-black text-white">Manage Offered Services & Classes</h2>
              <button
                onClick={() => setEditModal({
                  type: 'service',
                  item: { title: '', subtitle: 'High energy session', img: '/class_hiit.jpg', category: 'Cardio', desc: 'Workout description' }
                })}
                className="btn-nova-neon px-5 py-2 text-xs font-black flex items-center gap-1.5 cursor-pointer"
              >
                <Plus className="w-4 h-4 stroke-[3]" /> Add New Service
              </button>
            </div>

            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {services.map((srv, idx) => (
                <div key={srv._id || idx} className="bg-[#13151b] p-4 rounded-3xl border border-[#1e222d] space-y-3 text-left shadow-xl relative flex flex-col justify-between">
                  <div className="relative h-40 rounded-2xl overflow-hidden bg-[#0b0c10]">
                    <img src={srv.img || '/class_hiit.jpg'} alt={srv.title} className="w-full h-full object-cover" />
                  </div>
                  <div>
                    <span className="text-[10px] font-black text-[#b5f63d] uppercase tracking-wider block">{srv.category}</span>
                    <h3 className="text-lg font-black text-white">{srv.title}</h3>
                    <p className="text-xs text-slate-300 font-medium line-clamp-2 pt-1">{srv.desc}</p>
                  </div>
                  <div className="flex gap-2 pt-3 border-t border-[#1e222d]">
                    <button
                      onClick={() => setEditModal({ type: 'service', item: { ...srv } })}
                      className="w-full py-2 rounded-xl bg-[#0b0c10] border border-[#1e222d] hover:border-[#b5f63d] text-white font-bold text-xs flex items-center justify-center gap-1.5 cursor-pointer"
                    >
                      <Edit3 className="w-3.5 h-3.5 text-[#b5f63d]" /> Edit
                    </button>
                    <button
                      onClick={() => deleteService(srv._id)}
                      className="py-2 px-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] hover:border-red-500 text-slate-400 hover:text-red-400 text-xs font-bold cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 5: GYM CONTACT & DETAILS */}
        {activeTab === 'contact' && (
          <div className="bg-[#13151b] p-6 sm:p-8 rounded-3xl border border-[#1e222d] shadow-2xl max-w-3xl space-y-6 text-left">
            <div className="space-y-1">
              <span className="text-xs font-black text-[#b5f63d] uppercase tracking-wider block">Landing Page Info Settings</span>
              <h2 className="text-2xl font-black text-white">Contact & Social Media Details</h2>
            </div>

            <form onSubmit={saveGymInfo} className="space-y-4">
              <div className="space-y-1.5">
                <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider">Gym Name</label>
                <input
                  type="text"
                  value={gymInfo.name || ''}
                  onChange={(e) => setGymInfo({ ...gymInfo, name: e.target.value })}
                  className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-bold focus:border-[#b5f63d]"
                />
              </div>

              <div className="space-y-1.5">
                <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider">Address</label>
                <textarea
                  rows={2}
                  value={gymInfo.address || ''}
                  onChange={(e) => setGymInfo({ ...gymInfo, address: e.target.value })}
                  className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-medium focus:border-[#b5f63d]"
                />
              </div>

              <div className="grid sm:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider">Helpline Phone Number</label>
                  <input
                    type="text"
                    value={gymInfo.phone || ''}
                    onChange={(e) => setGymInfo({ ...gymInfo, phone: e.target.value })}
                    className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-bold focus:border-[#b5f63d]"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider">Operating Hours</label>
                  <input
                    type="text"
                    value={gymInfo.hours || ''}
                    onChange={(e) => setGymInfo({ ...gymInfo, hours: e.target.value })}
                    className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-bold focus:border-[#b5f63d]"
                  />
                </div>
              </div>

              <div className="grid sm:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider">Google Rating</label>
                  <input
                    type="text"
                    value={gymInfo.rating || ''}
                    onChange={(e) => setGymInfo({ ...gymInfo, rating: e.target.value })}
                    className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-bold focus:border-[#b5f63d]"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider">Review Count</label>
                  <input
                    type="text"
                    value={gymInfo.reviewCount || ''}
                    onChange={(e) => setGymInfo({ ...gymInfo, reviewCount: e.target.value })}
                    className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-bold focus:border-[#b5f63d]"
                  />
                </div>
              </div>

              {/* SOCIAL MEDIA LINKS SECTION */}
              <div className="border-t border-[#1e222d] pt-4 space-y-4">
                <h3 className="text-sm font-black text-[#b5f63d] uppercase tracking-wider">Social Media & Messaging Links</h3>
                
                <div className="grid sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                      📷 Instagram Profile URL
                    </label>
                    <input
                      type="text"
                      placeholder="https://instagram.com/..."
                      value={gymInfo.instagramUrl || ''}
                      onChange={(e) => setGymInfo({ ...gymInfo, instagramUrl: e.target.value })}
                      className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-mono focus:border-[#b5f63d]"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                      📘 Facebook Page URL
                    </label>
                    <input
                      type="text"
                      placeholder="https://facebook.com/..."
                      value={gymInfo.facebookUrl || ''}
                      onChange={(e) => setGymInfo({ ...gymInfo, facebookUrl: e.target.value })}
                      className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-mono focus:border-[#b5f63d]"
                    />
                  </div>
                </div>

                <div className="grid sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                      ▶️ YouTube Channel URL
                    </label>
                    <input
                      type="text"
                      placeholder="https://youtube.com/..."
                      value={gymInfo.youtubeUrl || ''}
                      onChange={(e) => setGymInfo({ ...gymInfo, youtubeUrl: e.target.value })}
                      className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-mono focus:border-[#b5f63d]"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="block text-xs font-extrabold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                      💬 WhatsApp Direct Link
                    </label>
                    <input
                      type="text"
                      placeholder="https://wa.me/917084306574"
                      value={gymInfo.whatsappUrl || ''}
                      onChange={(e) => setGymInfo({ ...gymInfo, whatsappUrl: e.target.value })}
                      className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-white text-xs font-mono focus:border-[#b5f63d]"
                    />
                  </div>
                </div>
              </div>

              <div className="pt-2">
                <button
                  type="submit"
                  className="btn-nova-neon px-8 py-3.5 text-xs font-black flex items-center gap-2 cursor-pointer shadow-lg"
                >
                  <Save className="w-4 h-4" /> Save Contact & Social Details to MongoDB
                </button>
              </div>
            </form>
          </div>
        )}

      </main>

      {/* MODAL FOR ADDING / EDITING CONTENT */}
      <AnimatePresence>
        {editModal.type && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 text-left">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setEditModal({ type: null, item: null })} className="absolute inset-0 bg-[#0b0c10]/85 backdrop-blur-md" />
            <motion.div initial={{ opacity: 0, scale: 0.9, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.9, y: 20 }} className="relative w-full max-w-lg bg-[#13151b] rounded-3xl p-6 sm:p-8 border border-[#b5f63d]/40 text-white z-10 space-y-5 shadow-2xl">
              <div className="flex justify-between items-center border-b border-[#1e222d] pb-3">
                <h3 className="text-xl font-black text-white uppercase tracking-wider">
                  {editModal.item._id ? 'Edit' : 'Add New'} {editModal.type}
                </h3>
                <button onClick={() => setEditModal({ type: null, item: null })} className="p-1.5 rounded-full bg-[#0b0c10] text-slate-400 hover:text-white cursor-pointer"><X className="w-5 h-5" /></button>
              </div>

              {/* EDIT PLAN FORM */}
              {editModal.type === 'plan' && (
                <form onSubmit={savePlan} className="space-y-4">
                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-[#b5f63d]">Plan Name</label>
                    <input type="text" required value={editModal.item.name || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, name: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-bold text-white focus:border-[#b5f63d]" />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-1">
                      <label className="text-xs font-extrabold text-slate-300">Monthly Price</label>
                      <input type="text" required value={editModal.item.monthlyPrice || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, monthlyPrice: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-bold text-white focus:border-[#b5f63d]" />
                    </div>
                    <div className="space-y-1">
                      <label className="text-xs font-extrabold text-slate-300">Yearly Price</label>
                      <input type="text" required value={editModal.item.yearlyPrice || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, yearlyPrice: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-bold text-white focus:border-[#b5f63d]" />
                    </div>
                  </div>
                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-300">Features (Comma-separated)</label>
                    <textarea rows={3} value={Array.isArray(editModal.item.features) ? editModal.item.features.join(', ') : editModal.item.features || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, features: e.target.value.split(',').map((s: string) => s.trim()) } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs text-white focus:border-[#b5f63d]" />
                  </div>
                  <button type="submit" className="w-full py-3.5 rounded-2xl btn-nova-neon text-[#0b0c10] font-black text-xs cursor-pointer">Save Plan to MongoDB →</button>
                </form>
              )}

              {/* EDIT TRAINER FORM */}
              {editModal.type === 'trainer' && (
                <form onSubmit={saveTrainer} className="space-y-4">
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-1">
                      <label className="text-xs font-extrabold text-[#b5f63d]">Trainer Name</label>
                      <input type="text" required value={editModal.item.name || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, name: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-bold text-white focus:border-[#b5f63d]" />
                    </div>
                    <div className="space-y-1">
                      <label className="text-xs font-extrabold text-slate-300">Category</label>
                      <input type="text" required value={editModal.item.category || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, category: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-bold text-white focus:border-[#b5f63d]" />
                    </div>
                  </div>

                  {/* Image Management Section */}
                  <div className="space-y-2 border-t border-[#1e222d] pt-3">
                    <label className="text-xs font-extrabold text-[#b5f63d] flex items-center gap-1.5">
                      🖼️ Profile Image URL / Path
                    </label>
                    <div className="flex gap-3 items-center">
                      <input
                        type="text"
                        required
                        placeholder="/trainer_hero.jpg or https://..."
                        value={editModal.item.image || ''}
                        onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, image: e.target.value } })}
                        className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-mono text-white focus:border-[#b5f63d]"
                      />
                      {/* Live Image Preview */}
                      <div className="w-12 h-12 rounded-xl overflow-hidden bg-[#0b0c10] border border-[#b5f63d]/40 shrink-0">
                        <img src={editModal.item.image || '/trainer_hero.jpg'} alt="Preview" className="w-full h-full object-cover" />
                      </div>
                    </div>

                    {/* Quick Preset Selector */}
                    <div className="space-y-1 pt-1">
                      <span className="text-[10px] text-slate-400 font-semibold block">Quick Select Preset Photo:</span>
                      <div className="flex flex-wrap gap-2">
                        {['/trainer_ava.jpg', '/trainer_lily.jpg', '/trainer_ethan.jpg', '/trainer_noah.jpg', '/trainer_hero.jpg', '/hero_athlete.jpg'].map((path) => (
                          <button
                            key={path}
                            type="button"
                            onClick={() => setEditModal({ ...editModal, item: { ...editModal.item, image: path } })}
                            className={`px-2.5 py-1 rounded-lg text-[10px] font-bold border transition-all cursor-pointer ${
                              editModal.item.image === path
                                ? 'bg-[#b5f63d] text-[#0b0c10] border-[#b5f63d]'
                                : 'bg-[#0b0c10] text-slate-300 border-[#1e222d] hover:border-slate-500'
                            }`}
                          >
                            {path.replace('/', '')}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-300">Specialties</label>
                    <input type="text" value={editModal.item.specialties || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, specialties: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs text-white focus:border-[#b5f63d]" />
                  </div>
                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-300">Full Bio</label>
                    <textarea rows={2} value={editModal.item.fullBio || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, fullBio: e.target.value, description: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs text-white focus:border-[#b5f63d]" />
                  </div>
                  <button type="submit" className="w-full py-3.5 rounded-2xl btn-nova-neon text-[#0b0c10] font-black text-xs cursor-pointer">Save Trainer to MongoDB →</button>
                </form>
              )}

              {/* EDIT SERVICE FORM */}
              {editModal.type === 'service' && (
                <form onSubmit={saveService} className="space-y-4">
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-1">
                      <label className="text-xs font-extrabold text-[#b5f63d]">Service Title</label>
                      <input type="text" required value={editModal.item.title || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, title: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-bold text-white focus:border-[#b5f63d]" />
                    </div>
                    <div className="space-y-1">
                      <label className="text-xs font-extrabold text-slate-300">Category</label>
                      <input type="text" required value={editModal.item.category || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, category: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-bold text-white focus:border-[#b5f63d]" />
                    </div>
                  </div>

                  {/* Image Management Section */}
                  <div className="space-y-2 border-t border-[#1e222d] pt-3">
                    <label className="text-xs font-extrabold text-[#b5f63d] flex items-center gap-1.5">
                      🖼️ Service Image URL / Path
                    </label>
                    <div className="flex gap-3 items-center">
                      <input
                        type="text"
                        required
                        placeholder="/class_hiit.jpg or https://..."
                        value={editModal.item.img || ''}
                        onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, img: e.target.value } })}
                        className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs font-mono text-white focus:border-[#b5f63d]"
                      />
                      {/* Live Image Preview */}
                      <div className="w-12 h-12 rounded-xl overflow-hidden bg-[#0b0c10] border border-[#b5f63d]/40 shrink-0">
                        <img src={editModal.item.img || '/class_hiit.jpg'} alt="Preview" className="w-full h-full object-cover" />
                      </div>
                    </div>

                    {/* Quick Preset Selector */}
                    <div className="space-y-1 pt-1">
                      <span className="text-[10px] text-slate-400 font-semibold block">Quick Select Preset Photo:</span>
                      <div className="flex flex-wrap gap-2">
                        {['/class_hiit.jpg', '/class_yoga.jpg', '/class_strength.jpg', '/class_cycling.jpg', '/gym_interior_neon.jpg', '/hero_athlete.jpg'].map((path) => (
                          <button
                            key={path}
                            type="button"
                            onClick={() => setEditModal({ ...editModal, item: { ...editModal.item, img: path } })}
                            className={`px-2.5 py-1 rounded-lg text-[10px] font-bold border transition-all cursor-pointer ${
                              editModal.item.img === path
                                ? 'bg-[#b5f63d] text-[#0b0c10] border-[#b5f63d]'
                                : 'bg-[#0b0c10] text-slate-300 border-[#1e222d] hover:border-slate-500'
                            }`}
                          >
                            {path.replace('/', '')}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-300">Description</label>
                    <textarea rows={3} value={editModal.item.desc || ''} onChange={(e) => setEditModal({ ...editModal, item: { ...editModal.item, desc: e.target.value } })} className="w-full p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] text-xs text-white focus:border-[#b5f63d]" />
                  </div>
                  <button type="submit" className="w-full py-3.5 rounded-2xl btn-nova-neon text-[#0b0c10] font-black text-xs cursor-pointer">Save Service to MongoDB →</button>
                </form>
              )}

            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <footer className="text-center py-6 text-[11px] text-slate-500 font-medium border-t border-[#1e222d]">
        <p>© {new Date().getFullYear()} Club 100 The Gym • Admin Control Dashboard</p>
      </footer>

    </div>
  );
}
