import svgPaths from "./svg-pqfvhu2ekl";
import imgQrCode from "figma:asset/3b60c10337ed98575afbe11b75abc08001588f4d.png";

function Footer() {
  return (
    <div className="absolute h-[530px] left-0 top-[2770px] w-[2550px]" data-name="footer">
      <div className="absolute h-[280px] left-[2047px] top-[160px] w-[282px]" data-name="qr-code">
        <img alt="" className="absolute inset-0 max-w-none object-50%-50% object-cover pointer-events-none size-full" src={imgQrCode} />
      </div>
      <div className="absolute flex flex-col font-['Manrope:SemiBold',_sans-serif] font-semibold justify-center leading-[0] left-[1957px] text-[#212121] text-[40px] text-nowrap top-[123px] tracking-[0.8px] translate-y-[-50%]">
        <p className="leading-[1.2] whitespace-pre">Otros métodos de pago</p>
      </div>
      <div className="absolute font-['Inter:SemiBold',_sans-serif] leading-[1.2] left-[1098px] not-italic text-[#212121] text-[0px] text-[40px] top-[122px] tracking-[0.8px] w-[738px]">
        <p className="font-['Manrope:SemiBold',_sans-serif] font-semibold mb-[12px]">Contacto:</p>
        <p className="font-['Manrope:Regular',_sans-serif] font-normal mb-[12px]">Edison Palacios</p>
        <p className="font-['Manrope:Regular',_sans-serif] font-normal mb-[12px]">edison@nocturno.studio</p>
        <p className="font-['Manrope:Regular',_sans-serif] font-normal mb-[12px]">
          <span>{`Web: `}</span>
          <a className="[text-decoration-skip-ink:none] [text-underline-position:from-font] cursor-pointer decoration-solid underline" href="https://nocturno.studio/">
            <span className="[text-decoration-skip-ink:none] [text-underline-position:from-font] decoration-solid font-['Manrope:Regular',_sans-serif] font-normal leading-[1.2] text-[40px] tracking-[0.8px]" href="https://nocturno.studio/">
              nocturno.studio
            </span>
          </a>
        </p>
        <p className="font-['Manrope:Regular',_sans-serif] font-normal">+51 999 999 999</p>
      </div>
      <div className="absolute flex flex-col font-['Manrope:SemiBold',_sans-serif] font-semibold justify-center leading-[1.2] left-[120px] text-[#212121] text-[40px] top-[266px] tracking-[0.8px] translate-y-[-50%] w-[756px]">
        <p className="mb-[12px]">Pagos:</p>
        <p className="font-['Manrope:Regular',_sans-serif] font-normal">Cuentas Bancarias</p>
      </div>
      <div className="absolute bg-[#a6a6a6] h-[2px] left-0 top-0 w-[2550px]" data-name="divider" />
      <div className="absolute bg-[#a6a6a6] h-[530px] left-[1836px] top-0 w-[2px]" data-name="divider" />
    </div>
  );
}

function TotalRow() {
  return (
    <div className="content-stretch flex font-['Manrope:Medium',_sans-serif] font-medium gap-[8px] items-start leading-[0] relative shrink-0 text-[40px]" data-name="total-row">
      <div className="flex flex-col justify-center relative shrink-0 text-black w-[381px]">
        <p className="leading-[1.2]">Sub-Total</p>
      </div>
      <div className="flex flex-col justify-center relative shrink-0 text-[#212121] text-right w-[432px]">
        <p className="leading-[1.2]">S/ 00.00</p>
      </div>
    </div>
  );
}

function Total() {
  return (
    <div className="content-stretch flex font-['Manrope:SemiBold',_sans-serif] font-semibold gap-[8px] items-start leading-[0] relative shrink-0 text-[40px]" data-name="total">
      <div className="flex flex-col justify-center relative shrink-0 text-black w-[381px]">
        <p className="leading-[1.2]">Total</p>
      </div>
      <div className="flex flex-col justify-center relative shrink-0 text-[#212121] text-right w-[432px]">
        <p className="leading-[1.2]">S/ 000.00</p>
      </div>
    </div>
  );
}

function Total1() {
  return (
    <div className="absolute bg-white box-border content-stretch flex flex-col gap-[40px] items-start p-[64px] top-[1681px]" data-name="total" style={{ left: "calc(58.333% - 6.5px)" }}>
      <div aria-hidden="true" className="absolute border-2 border-[rgba(33,33,33,0.4)] border-solid inset-0 pointer-events-none" />
      <TotalRow />
      <div className="bg-[#212121] h-[2px] shrink-0 w-[821px]" data-name="divider" />
      <Total />
    </div>
  );
}

function Total2() {
  return (
    <div className="absolute h-[241px] leading-[0] left-[120px] text-[#212121] top-[561px] w-[2310px]" data-name="total">
      <div className="absolute flex flex-col font-['Inter:SemiBold',_sans-serif] justify-center leading-[1.2] left-0 not-italic text-[0px] text-[40px] top-[114px] tracking-[0.8px] translate-y-[-50%] w-[756px]">
        <p className="font-['Manrope:SemiBold',_sans-serif] font-semibold mb-[12px]">Cotización para:</p>
        <p className="font-['Manrope:Regular',_sans-serif] font-normal mb-[12px]">Luis Pflucker</p>
        <p className="font-['Manrope:Regular',_sans-serif] font-normal">Lima, Perú.</p>
      </div>
      <div className="absolute flex flex-col font-['Manrope:SemiBold',_sans-serif] font-semibold justify-center left-[2310px] text-[40px] text-right top-[24px] tracking-[0.8px] translate-x-[-100%] translate-y-[-50%] w-[756px]">
        <p className="leading-[1.2]">Total:</p>
      </div>
      <div className="absolute flex flex-col font-['Manrope:SemiBold',_sans-serif] font-semibold justify-center left-[2310px] text-[104px] text-right top-[179px] tracking-[-5.2px] translate-x-[-100%] translate-y-[-50%] w-[756px]">
        <p className="leading-[1.19]">S/ 000.00</p>
      </div>
    </div>
  );
}

function Group() {
  return (
    <div className="absolute contents inset-[-8.08%_-0.04%_-7.85%_19.14%] leading-[0] not-italic text-[41.576px] text-black text-nowrap" data-name="Group">
      <div className="absolute font-['Roc_Grotesk:Wide_ExtraBold',_sans-serif] inset-[-8.08%_-0.04%_39.9%_19.14%]">
        <p className="leading-[normal] text-nowrap whitespace-pre">NOCTURNO</p>
      </div>
      <div className="absolute font-['Roc_Grotesk:Regular',_sans-serif] inset-[39.67%_39.44%_-7.85%_19.14%]">
        <p className="leading-[normal] text-nowrap whitespace-pre">STUDIO</p>
      </div>
    </div>
  );
}

function Group1() {
  return (
    <div className="absolute bottom-[13.29%] left-0 right-[85.75%] top-[7.51%]" data-name="Group">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 52 70">
        <g id="Group">
          <path d={svgPaths.p2e60300} fill="var(--fill-0, black)" id="Vector" />
          <path d={svgPaths.p2ab27150} fill="var(--fill-0, black)" id="Vector_2" />
        </g>
      </svg>
    </div>
  );
}

function Layer1() {
  return (
    <div className="absolute inset-[40%_82.23%_40%_3.57%] overflow-clip" data-name="Layer_1">
      <Group />
      <Group1 />
    </div>
  );
}

function Header() {
  return (
    <div className="absolute h-[440px] left-0 top-0 w-[2550px]" data-name="header">
      <div className="absolute flex flex-col font-['Manrope:Regular',_sans-serif] font-normal justify-center leading-[0] left-[2430px] text-[#212121] text-[40px] text-right top-[308px] translate-x-[-100%] translate-y-[-50%] w-[368px]">
        <p className="leading-[1.2]">20 días</p>
      </div>
      <div className="absolute flex flex-col font-['Manrope:SemiBold',_sans-serif] font-semibold justify-center leading-[0] left-[1601px] text-[#212121] text-[40px] top-[308px] tracking-[-1.2px] translate-y-[-50%] w-[310px]">
        <p className="leading-[1.2]">Vigencia</p>
      </div>
      <div className="absolute flex flex-col font-['Manrope:Regular',_sans-serif] font-normal justify-center leading-[0] left-[2430px] text-[#212121] text-[40px] text-right top-[236px] translate-x-[-100%] translate-y-[-50%] w-[348px]">
        <p className="leading-[1.2]">Febrero 24, 2022</p>
      </div>
      <div className="absolute flex flex-col font-['Manrope:SemiBold',_sans-serif] font-semibold justify-center leading-[0] left-[1601px] text-[#212121] text-[40px] top-[236px] tracking-[-1.2px] translate-y-[-50%] w-[314px]">
        <p className="leading-[1.2]">Fecha de emisión</p>
      </div>
      <div className="absolute flex flex-col font-['Manrope:Regular',_sans-serif] font-normal justify-center leading-[0] left-[2430px] text-[#212121] text-[40px] text-right top-[164px] translate-x-[-100%] translate-y-[-50%] w-[368px]">
        <p className="leading-[1.2]">2023023</p>
      </div>
      <div className="absolute flex flex-col font-['Manrope:SemiBold',_sans-serif] font-semibold justify-center leading-[0] left-[1601px] text-[#212121] text-[40px] top-[164px] tracking-[-1.2px] translate-y-[-50%] w-[305px]">
        <p className="leading-[1.2]">Factura #</p>
      </div>
      <div className="absolute bg-[#a6a6a6] h-[2px] left-0 top-[440px] w-[2550px]" data-name="divider" />
      <div className="absolute bg-[#a6a6a6] h-[442px] left-[1452px] top-0 w-[2px]" data-name="divider" />
      <div className="absolute bg-[#a6a6a6] h-[442px] left-[526px] top-0 w-[2px]" data-name="divider" />
      <div className="absolute flex flex-col font-['Manrope:SemiBold',_sans-serif] font-semibold justify-center leading-[0] left-[634px] text-[#212121] text-[104px] top-[170px] tracking-[-5.2px] translate-y-[-50%] w-[772px]">
        <p className="leading-[1.19]">Cotización</p>
      </div>
      <div className="absolute font-['Manrope:Regular',_sans-serif] font-normal leading-[0] left-[634px] text-[#212121] text-[40px] top-[236px] w-[675px]">
        <p className="leading-[1.2]">Videos animados para RRSS</p>
      </div>
      <Layer1 />
    </div>
  );
}

function Headline() {
  return (
    <div className="font-['Manrope:Bold',_sans-serif] font-bold h-[36px] leading-[0] relative shrink-0 text-[#212121] text-[30px] text-nowrap tracking-[3.6px] uppercase w-[2182px]" data-name="headline">
      <div className="absolute flex flex-col justify-center left-[2182px] text-right top-[18px] translate-x-[-100%] translate-y-[-50%]">
        <p className="leading-[1.2] text-nowrap whitespace-pre">{`TOTAL `}</p>
      </div>
      <div className="absolute flex flex-col justify-center left-0 top-[18px] translate-y-[-50%]">
        <p className="leading-[1.2] text-nowrap whitespace-pre">caRGOS</p>
      </div>
      <div className="absolute flex flex-col justify-center left-[1361px] top-[18px] translate-y-[-50%]">
        <p className="leading-[1.2] text-nowrap whitespace-pre">CaNTIDAD</p>
      </div>
    </div>
  );
}

function Text() {
  return (
    <div className="absolute content-stretch flex font-['Manrope:Medium',_sans-serif] font-medium gap-[130px] items-center leading-[0] left-0 text-[40px] top-[66px]" data-name="text">
      <div className="flex flex-col justify-center relative shrink-0 text-[#212121] w-[1231px]">
        <p className="leading-[1.2]">Videos animados para RRSS</p>
      </div>
      <div className="flex flex-col justify-center relative shrink-0 text-black w-[259px]">
        <p className="leading-[1.2]">1</p>
      </div>
      <div className="flex flex-col justify-center relative shrink-0 text-[#212121] text-right w-[432px]">
        <p className="leading-[1.2]">S/ 000.00</p>
      </div>
    </div>
  );
}

function LineItem() {
  return (
    <div className="h-[388px] relative shrink-0 w-[2182px]" data-name="line-item">
      <div className="absolute bg-[#a6a6a6] h-[2px] left-[-64px] top-0 w-[2310px]" data-name="divider" />
      <div className="absolute bg-[#a6a6a6] h-[451px] left-[1684px] top-0 w-[2px]" data-name="divider" />
      <div className="absolute bg-[#a6a6a6] h-[451px] left-[1297px] top-0 w-[2px]" data-name="divider" />
      <Text />
      <div className="absolute font-['Manrope:Regular',_sans-serif] font-normal h-[247px] leading-[0] left-0 opacity-80 text-[#212121] text-[30px] top-[141px] w-[1231px]">
        <p className="leading-[1.2] mb-0">Produciremos y editaremos videos para nuestro cliente en sus oficinas.</p>
        <p className="leading-[1.2] mb-0">&nbsp;</p>
        <p className="leading-[1.2] mb-0">Entregables:</p>
        <ol className="list-decimal mb-0" start="1">
          <li className="ms-[45px]">
            <span className="leading-[1.2]">4 videos diseñados y animados.</span>
          </li>
        </ol>
        <p className="leading-[1.2] mb-0">&nbsp;</p>
        <p className="leading-[1.2] mb-0">Fecha de entrega:</p>
        <p className="leading-[1.2]">Hasta 5 días para todos los entregables.</p>
      </div>
    </div>
  );
}

function Charges() {
  return (
    <div className="absolute bg-white box-border content-stretch flex flex-col gap-[64px] items-start left-0 p-[64px] top-0 w-[2310px]" data-name="charges">
      <div aria-hidden="true" className="absolute border-2 border-[rgba(33,33,33,0.4)] border-solid inset-0 pointer-events-none" />
      <Headline />
      <LineItem />
    </div>
  );
}

function Table() {
  return (
    <div className="absolute h-[615px] left-[120px] top-[910px] w-[2310px]" data-name="table">
      <Charges />
    </div>
  );
}

export default function Frame4() {
  return (
    <div className="bg-white relative size-full">
      <Footer />
      <div className="absolute font-['Inter:SemiBold',_sans-serif] leading-[0] left-[120px] not-italic opacity-80 text-[#212121] text-[0px] top-[1688px] tracking-[0.8px] w-[1016px]">
        <p className="font-['Manrope:SemiBold',_sans-serif] font-semibold leading-[1.2] mb-[30px] text-[40px]">Observaciones:</p>
        <ol className="list-decimal" start="1">
          <li style={{ marginInlineStart: "calc(1.5 * 1 * var(--list-marker-font-size, 0))" }}>
            <span className="font-['Manrope:Regular',_sans-serif] font-normal leading-[1.2] text-[30px]">Nuestro cliente deberá pagar el 50% de anticipo del servicio y el otro 50% se deberá pagar al finalizar el proyecto o el mes.</span>
          </li>
        </ol>
      </div>
      <Total1 />
      <Total2 />
      <Header />
      <Table />
    </div>
  );
}