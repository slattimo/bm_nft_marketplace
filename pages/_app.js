import Script from 'next/script';
import { ThemeProvider } from 'next-themes'; // External imports

import { Navbar, Footer } from '../components'; // Internal imports

import '../styles/globals.css';

const MyApp = ({ Component, pageProps }) => (
  <ThemeProvider attribute="class">
    <div className="dark:bg-nft-dark bg-white min-h-screen">
      <Navbar />
      <Component {...pageProps} />
      <Footer />
    </div>

    <Script src="https://kit.fontawesome.com/974feef76a.js" crossOrigin="anonymous" />
  </ThemeProvider>
);

export default MyApp;
