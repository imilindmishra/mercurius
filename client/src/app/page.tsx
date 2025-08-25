import { SwapCard } from '../components/SwapCard';

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-900 text-white flex flex-col items-center p-4">
      <nav className="w-full flex justify-between items-center p-4 max-w-md mx-auto">
        <h1 className="text-2xl font-bold">Mercurius</h1>        
      </nav>
      <main className="flex flex-1 items-center justify-center w-full">
        <SwapCard />
      </main>
    </div>
  );
}