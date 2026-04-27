interface LogoIdeallyProps {
  className?: string;
  size?: number;
}

export function LogoIdeally({ className = "", size = 48 }: LogoIdeallyProps) {
  return (
    <div 
      className={`relative bg-white rounded-lg flex items-center justify-center ${className}`}
      style={{ width: size, height: size }}
    >
      <svg 
        width={size * 0.8} 
        height={size * 0.8} 
        viewBox="0 0 184 155" 
        fill="none" 
        className="block"
      >
        <g>
          <path 
            d="M175.555 -4.76837e-07C187.741 3.48352 186.423 20.9645 173.642 22.0918L28.93 22.9532L93.6222 151.362C94.2429 152.591 94.1542 153.997 92.7988 154.58H91.6967C90.924 154.352 85.9331 146.447 85.021 145.092C56.7729 102.935 29.9941 59.7519 1.80924 17.5443C-2.66234 11.1979 1.6699 2.45746 9.16896 1.71009" 
            fill="black" 
          />
          <path 
            d="M59.0403 49.238C63.5107 49.238 67.1347 45.614 67.1347 41.1435C67.1347 36.6731 63.5107 33.0491 59.0403 33.0491C54.5699 33.0491 50.9459 36.6731 50.9459 41.1435C50.9459 45.614 54.5699 49.238 59.0403 49.238Z" 
            fill="black" 
          />
        </g>
      </svg>
    </div>
  );
}