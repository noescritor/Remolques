import svgPaths from "./svg-uyqp5z14td";
import imgEllipse1 from "figma:asset/18a2b7e7666eb599cd25d002678e96cca6bfe095.png";
import { img, img1, img2 } from "./svg-m8ax7";

function SideNav() {
  return (
    <div className="relative size-full" data-name="Side Nav">
      <div className="absolute content-stretch flex flex-col gap-[24px] items-start left-[32px] top-[203px]" data-name="Nav Items">
        <div className="flex flex-col font-['Work_Sans:ExtraBold',_sans-serif] font-extrabold justify-center leading-[0] relative shrink-0 text-[24px] text-nowrap text-white tracking-[0.24px]">
          <p className="leading-[1.5] whitespace-pre">Dashboard</p>
        </div>
        <div className="content-stretch flex flex-col items-center relative shrink-0" data-name="Item">
          <div className="flex flex-col font-['Work_Sans:ExtraBold',_sans-serif] font-extrabold justify-center leading-[0] relative shrink-0 text-[24px] text-nowrap text-white tracking-[0.24px]">
            <p className="leading-[1.5] whitespace-pre">Contacts</p>
          </div>
          <div className="bg-[#47c6f5] h-[3px] shrink-0 w-full" />
        </div>
        <div className="content-stretch flex flex-col items-center relative shrink-0" data-name="Item">
          <div className="flex flex-col font-['Work_Sans:ExtraBold',_sans-serif] font-extrabold justify-center leading-[0] relative shrink-0 text-[24px] text-nowrap text-white tracking-[0.24px]">
            <p className="leading-[1.5] whitespace-pre">Order History</p>
          </div>
        </div>
        <div className="content-stretch flex flex-col items-center relative shrink-0" data-name="Item">
          <div className="flex flex-col font-['Work_Sans:ExtraBold',_sans-serif] font-extrabold justify-center leading-[0] relative shrink-0 text-[24px] text-nowrap text-white tracking-[0.24px]">
            <p className="leading-[1.5] whitespace-pre">Documents</p>
          </div>
        </div>
      </div>
      <div className="absolute flex flex-col font-['Work_Sans:ExtraBold',_sans-serif] font-extrabold justify-center leading-[0] left-[32px] text-[#47c6f5] text-[32px] text-nowrap top-[47px] tracking-[0.32px] translate-y-[-50%]">
        <p className="leading-[1.5] whitespace-pre">AFH</p>
      </div>
      <div className="absolute flex flex-col font-['Work_Sans:ExtraBold',_sans-serif] font-extrabold justify-center leading-[0] left-[33px] text-[32px] text-nowrap top-[48px] tracking-[0.32px] translate-y-[-50%]">
        <p className="leading-[1.5] whitespace-pre">AFH</p>
      </div>
      <div className="absolute bottom-[32px] left-[32px] size-[40px]">
        <img alt="" className="block max-w-none size-full" height="40" src={imgEllipse1} width="40" />
      </div>
    </div>
  );
}

function IconEllipsisV() {
  return (
    <div className="relative size-full" data-name="Icon / ellipsis v">
      <div className="absolute bottom-0 left-[37.5%] right-[37.5%] top-0" data-name="ellipsis-v">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 16">
          <g id="ellipsis-v">
            <path d={svgPaths.p1a3cd700} fill="var(--fill-0, #6B6C7E)" />
            <path d={svgPaths.p23851d00} fill="var(--fill-0, #6B6C7E)" />
            <path d={svgPaths.p16ea2380} fill="var(--fill-0, #6B6C7E)" />
          </g>
        </svg>
      </div>
    </div>
  );
}

function RowCell() {
  return (
    <div className="relative size-full" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <div className="relative shrink-0 size-[16px]" data-name="Icon Left">
            <IconEllipsisV />
          </div>
          <div className="basis-0 content-stretch flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] grow items-start leading-[0] min-h-px min-w-px not-italic relative shrink-0 text-[#272833]" data-name="Text">
            <div className="flex flex-col justify-center relative shrink-0 text-[14px] w-full">
              <p className="leading-[1.5]">Primary Text</p>
            </div>
            <div className="flex flex-col justify-center opacity-70 relative shrink-0 text-[13px] w-full">
              <p className="leading-[1.5]">Secondary Text</p>
            </div>
          </div>
          <div className="relative shrink-0 size-[16px]" data-name="Icon Right">
            <IconEllipsisV />
          </div>
        </div>
      </div>
    </div>
  );
}

function Label() {
  return (
    <div className="bg-white relative rounded-[2px] size-full" data-name="Label">
      <div aria-hidden="true" className="absolute border border-[#89a7e0] border-solid inset-0 pointer-events-none rounded-[2px]" />
      <div className="flex flex-col items-center relative size-full">
        <div className="box-border content-stretch flex flex-col items-center px-[12px] py-[3px] relative size-full">
          <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#2e5aac] text-[12px] text-nowrap">
            <p className="leading-[1.5] whitespace-pre">LABEL TEXT</p>
          </div>
        </div>
      </div>
    </div>
  );
}

interface CellProps {
  type?: "Row" | "Header";
  content?: "Blank" | "Button" | "Checkbox" | "Icon" | "Label" | "Text";
  prop2ndText?: "False" | "True";
  iconLeft?: "False" | "True";
  iconRight?: "False" | "True";
}

function Cell({ type = "Row", content = "Text", prop2ndText = "False", iconLeft = "False", iconRight = "False" }: CellProps) {
  if (type === "Row" && content === "Text" && prop2ndText === "True" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Text, 2nd Text=True, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="basis-0 content-stretch flex flex-col grow items-start leading-[0] min-h-px min-w-px not-italic relative shrink-0 text-[#272833]" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center relative shrink-0 text-[14px] w-full">
                  <p className="leading-[1.5]">Primary Text</p>
                </div>
                <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center opacity-70 relative shrink-0 text-[13px] w-full">
                  <p className="leading-[1.5]">Secondary Text</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Text" && prop2ndText === "True" && iconLeft === "True" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Text, 2nd Text=True, Icon Left=True, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="relative shrink-0 size-[16px]" data-name="Icon Left">
                <div className="absolute inset-[18.75%_31.25%]" data-name="drag-dots">
                  <img alt="" className="block max-w-none size-full" src={img} />
                </div>
              </div>
              <div className="basis-0 content-stretch flex flex-col grow items-start leading-[0] min-h-px min-w-px not-italic relative shrink-0 text-[#272833]" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center relative shrink-0 text-[14px] w-full">
                  <p className="leading-[1.5]">Primary Text</p>
                </div>
                <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center opacity-70 relative shrink-0 text-[13px] w-full">
                  <p className="leading-[1.5]">Secondary Text</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Text" && prop2ndText === "True" && iconLeft === "False" && iconRight === "True") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Text, 2nd Text=True, Icon Left=False, Icon Right=True">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="basis-0 content-stretch flex flex-col grow items-start leading-[0] min-h-px min-w-px not-italic relative shrink-0 text-[#272833]" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center relative shrink-0 text-[14px] w-full">
                  <p className="leading-[1.5]">Primary Text</p>
                </div>
                <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center opacity-70 relative shrink-0 text-[13px] w-full">
                  <p className="leading-[1.5]">Secondary Text</p>
                </div>
              </div>
              <div className="relative shrink-0 size-[16px]" data-name="Icon Right">
                <div className="absolute bottom-0 left-[37.5%] right-[37.5%] top-0" data-name="ellipsis-v">
                  <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 16">
                    <g id="ellipsis-v">
                      <path d={svgPaths.p1a3cd700} fill="var(--fill-0, #6B6C7E)" />
                      <path d={svgPaths.p23851d00} fill="var(--fill-0, #6B6C7E)" />
                      <path d={svgPaths.p16ea2380} fill="var(--fill-0, #6B6C7E)" />
                    </g>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Button" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Button, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="bg-[#0b5fff] box-border content-stretch flex gap-[4px] items-center px-[16px] py-[8px] relative rounded-[4px] shrink-0" data-name="Icon Left">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[16px] text-center text-nowrap text-white">
                  <p className="leading-[1.5] whitespace-pre">Button</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Label" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Label, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="bg-white box-border content-stretch flex flex-col items-center px-[12px] py-[3px] relative rounded-[2px] shrink-0" data-name="Icon Left">
                <Label />
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Checkbox" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Checkbox, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="bg-white content-stretch flex flex-col items-center justify-center relative rounded-[2px] shrink-0" data-name="Icon Left">
                <div aria-hidden="true" className="absolute border border-[#cdced9] border-solid inset-0 pointer-events-none rounded-[2px]" />
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Checkbox" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Checkbox, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="bg-white content-stretch flex flex-col items-center justify-center relative rounded-[2px] shrink-0" data-name="Icon Left">
                <div aria-hidden="true" className="absolute border border-[#cdced9] border-solid inset-0 pointer-events-none rounded-[2px]" />
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Text" && prop2ndText === "False" && iconLeft === "True" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Text, 2nd Text=False, Icon Left=True, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="relative shrink-0 size-[16px]" data-name="Icon Left">
                <div className="absolute inset-[18.75%_31.25%]" data-name="drag-dots">
                  <img alt="" className="block max-w-none size-full" src={img} />
                </div>
              </div>
              <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[14px] w-full">
                  <p className="leading-[1.5]">Primary Text</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Text" && prop2ndText === "False" && iconLeft === "False" && iconRight === "True") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Text, 2nd Text=False, Icon Left=False, Icon Right=True">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[14px] w-full">
                  <p className="leading-[1.5]">Primary Text</p>
                </div>
              </div>
              <div className="relative shrink-0 size-[16px]" data-name="Icon Right">
                <div className="absolute bottom-0 left-[37.5%] right-[37.5%] top-0" data-name="ellipsis-v">
                  <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 16">
                    <g id="ellipsis-v">
                      <path d={svgPaths.p1a3cd700} fill="var(--fill-0, #6B6C7E)" />
                      <path d={svgPaths.p23851d00} fill="var(--fill-0, #6B6C7E)" />
                      <path d={svgPaths.p16ea2380} fill="var(--fill-0, #6B6C7E)" />
                    </g>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Icon" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Icon, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="relative shrink-0 size-[16px]" data-name="Icon Left">
                <div className="absolute bottom-0 left-[37.5%] right-[37.5%] top-0" data-name="ellipsis-v">
                  <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 16">
                    <g id="ellipsis-v">
                      <path d={svgPaths.p1a3cd700} fill="var(--fill-0, #6B6C7E)" />
                      <path d={svgPaths.p23851d00} fill="var(--fill-0, #6B6C7E)" />
                      <path d={svgPaths.p16ea2380} fill="var(--fill-0, #6B6C7E)" />
                    </g>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Icon" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Icon, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="relative shrink-0 size-[16px]" data-name="Icon Left">
                <div className="absolute bottom-0 left-[37.5%] right-[37.5%] top-0" data-name="ellipsis-v">
                  <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 16">
                    <g id="ellipsis-v">
                      <path d={svgPaths.p1a3cd700} fill="var(--fill-0, #6B6C7E)" />
                      <path d={svgPaths.p23851d00} fill="var(--fill-0, #6B6C7E)" />
                      <path d={svgPaths.p16ea2380} fill="var(--fill-0, #6B6C7E)" />
                    </g>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Row" && content === "Blank" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Blank, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 size-full" />
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Text" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Text, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[16px] w-full">
                  <p className="leading-[1.5]">Header</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Text" && prop2ndText === "True" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Text, 2nd Text=True, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="basis-0 content-stretch flex flex-col grow items-start leading-[0] min-h-px min-w-px not-italic relative shrink-0 text-[#272833]" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center relative shrink-0 text-[16px] w-full">
                  <p className="leading-[1.5]">Header</p>
                </div>
                <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center opacity-70 relative shrink-0 text-[13px] w-full">
                  <p className="leading-[1.5]">Secondary Text</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Text" && prop2ndText === "False" && iconLeft === "True" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Text, 2nd Text=False, Icon Left=True, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="relative shrink-0 size-[16px]" data-name="Icon Left">
                <div className="absolute left-[5px] size-[10px] top-[6px]" data-name="Icon / order arrow down">
                  <div className="absolute inset-[12.5%_29.44%_12.5%_30%]" data-name="order-arrow-down">
                    <img alt="" className="block max-w-none size-full" src={img1} />
                  </div>
                </div>
                <div className="absolute left-px size-[10px] top-0" data-name="Icon / order arrow up">
                  <div className="absolute inset-[12.5%_29.38%_12.5%_30%]" data-name="order-arrow-up">
                    <img alt="" className="block max-w-none size-full" src={img2} />
                  </div>
                </div>
              </div>
              <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[16px] w-full">
                  <p className="leading-[1.5]">Header</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Text" && prop2ndText === "True" && iconLeft === "True" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Text, 2nd Text=True, Icon Left=True, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="relative shrink-0 size-[16px]" data-name="Icon Left">
                <div className="absolute left-[5px] size-[10px] top-[6px]" data-name="Icon / order arrow down">
                  <div className="absolute inset-[12.5%_29.44%_12.5%_30%]" data-name="order-arrow-down">
                    <img alt="" className="block max-w-none size-full" src={img1} />
                  </div>
                </div>
                <div className="absolute left-px size-[10px] top-0" data-name="Icon / order arrow up">
                  <div className="absolute inset-[12.5%_29.38%_12.5%_30%]" data-name="order-arrow-up">
                    <img alt="" className="block max-w-none size-full" src={img2} />
                  </div>
                </div>
              </div>
              <div className="basis-0 content-stretch flex flex-col grow items-start leading-[0] min-h-px min-w-px not-italic relative shrink-0 text-[#272833]" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center relative shrink-0 text-[16px] w-full">
                  <p className="leading-[1.5]">Header</p>
                </div>
                <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center opacity-70 relative shrink-0 text-[13px] w-full">
                  <p className="leading-[1.5]">Secondary Text</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Text" && prop2ndText === "False" && iconLeft === "False" && iconRight === "True") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Text, 2nd Text=False, Icon Left=False, Icon Right=True">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[16px] w-full">
                  <p className="leading-[1.5]">Header</p>
                </div>
              </div>
              <div className="relative shrink-0 size-[16px]" data-name="Icon Right">
                <div className="absolute left-[5px] size-[10px] top-[6px]" data-name="Icon / order arrow down">
                  <div className="absolute inset-[12.5%_29.44%_12.5%_30%]" data-name="order-arrow-down">
                    <img alt="" className="block max-w-none size-full" src={img1} />
                  </div>
                </div>
                <div className="absolute left-px size-[10px] top-0" data-name="Icon / order arrow up">
                  <div className="absolute inset-[12.5%_29.38%_12.5%_30%]" data-name="order-arrow-up">
                    <img alt="" className="block max-w-none size-full" src={img2} />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Text" && prop2ndText === "True" && iconLeft === "False" && iconRight === "True") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Text, 2nd Text=True, Icon Left=False, Icon Right=True">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
              <div className="basis-0 content-stretch flex flex-col grow items-start leading-[0] min-h-px min-w-px not-italic relative shrink-0 text-[#272833]" data-name="Text">
                <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center relative shrink-0 text-[16px] w-full">
                  <p className="leading-[1.5]">Header</p>
                </div>
                <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center opacity-70 relative shrink-0 text-[13px] w-full">
                  <p className="leading-[1.5]">Secondary Text</p>
                </div>
              </div>
              <div className="relative shrink-0 size-[16px]" data-name="Icon Right">
                <div className="absolute left-[5px] size-[10px] top-[6px]" data-name="Icon / order arrow down">
                  <div className="absolute inset-[12.5%_29.44%_12.5%_30%]" data-name="order-arrow-down">
                    <img alt="" className="block max-w-none size-full" src={img1} />
                  </div>
                </div>
                <div className="absolute left-px size-[10px] top-0" data-name="Icon / order arrow up">
                  <div className="absolute inset-[12.5%_29.38%_12.5%_30%]" data-name="order-arrow-up">
                    <img alt="" className="block max-w-none size-full" src={img2} />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  if (type === "Header" && content === "Blank" && prop2ndText === "False" && iconLeft === "False" && iconRight === "False") {
    return (
      <div className="content-stretch flex items-start relative size-full" data-name="Type=Header, Content=Blank, 2nd Text=False, Icon Left=False, Icon Right=False">
        <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
          <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
            <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 size-full" />
          </div>
        </div>
      </div>
    );
  }
  return (
    <div className="content-stretch flex items-start relative size-full" data-name="Type=Row, Content=Text, 2nd Text=False, Icon Left=False, Icon Right=False">
      <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
        <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
          <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
            <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
              <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[14px] w-full">
                <p className="leading-[1.5]">Primary Text</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function RowMainRecomponentizeDuplicate() {
  return (
    <div className="relative rounded-[12px] size-full" data-name="Row / Main (recomponentize & duplicate)">
      <div className="content-stretch flex flex-col items-start overflow-clip relative size-full">
        <div className="h-[0.001px] relative shrink-0 w-full" data-name="Row Styling / Default">
          <div className="absolute bg-white bottom-[-64px] h-[64px] left-0 right-0" data-name="Background" />
          <div className="absolute bg-[#e7e7ed] bottom-[-64px] h-px left-0 right-0" data-name="Border Bottom" />
        </div>
        <div className="content-stretch flex items-center overflow-clip relative shrink-0 w-[997px]" data-name="Cells">
          <div className="content-stretch flex items-start relative shrink-0 w-[48px]" data-name="Cell">
            <div className="basis-0 grow min-h-px min-w-px relative self-stretch shrink-0" data-name="Row Cell">
              <RowCell />
            </div>
          </div>
          <div className="basis-0 content-stretch flex grow h-[64px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
            <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
              <RowCell />
            </div>
          </div>
          <div className="basis-0 content-stretch flex grow h-[64px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
            <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
              <RowCell />
            </div>
          </div>
          <div className="content-stretch flex h-[64px] items-start relative shrink-0 w-[214px]" data-name="Cell">
            <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
              <RowCell />
            </div>
          </div>
          <div className="basis-0 content-stretch flex grow h-[64px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
            <Cell />
          </div>
          <div className="basis-0 content-stretch flex grow h-[64px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
            <Cell content="Label" />
          </div>
          <div className="content-stretch flex h-[64px] items-start relative shrink-0 w-[72px]" data-name="Cell">
            <Cell content="Icon" />
          </div>
        </div>
      </div>
      <div aria-hidden="true" className="absolute border border-[#e7e7ed] border-solid inset-[-0.5px] pointer-events-none rounded-[12.5px]" />
    </div>
  );
}

function RowCell1() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 size-full" />
      </div>
    </div>
  );
}

function Cell1() {
  return (
    <div className="content-stretch flex items-start relative shrink-0 size-[48px]" data-name="Cell">
      <RowCell1 />
    </div>
  );
}

function Text() {
  return (
    <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
      <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[16px] w-full">
        <p className="leading-[1.5]">First Name</p>
      </div>
    </div>
  );
}

function RowCell2() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <Text />
        </div>
      </div>
    </div>
  );
}

function Cell2() {
  return (
    <div className="basis-0 content-stretch flex grow h-[48px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
      <RowCell2 />
    </div>
  );
}

function Text1() {
  return (
    <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
      <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[16px] w-full">
        <p className="leading-[1.5]">Last Name</p>
      </div>
    </div>
  );
}

function RowCell3() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <Text1 />
        </div>
      </div>
    </div>
  );
}

function Cell3() {
  return (
    <div className="basis-0 content-stretch flex grow h-[48px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
      <RowCell3 />
    </div>
  );
}

function Text2() {
  return (
    <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
      <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[16px] w-full">
        <p className="leading-[1.5]">Email</p>
      </div>
    </div>
  );
}

function RowCell4() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <Text2 />
        </div>
      </div>
    </div>
  );
}

function Cell4() {
  return (
    <div className="content-stretch flex h-[48px] items-start relative shrink-0 w-[214px]" data-name="Cell">
      <RowCell4 />
    </div>
  );
}

function Text3() {
  return (
    <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
      <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[16px] w-full">
        <p className="leading-[1.5]">Phone</p>
      </div>
    </div>
  );
}

function RowCell5() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <Text3 />
        </div>
      </div>
    </div>
  );
}

function Cell5() {
  return (
    <div className="basis-0 content-stretch flex grow h-[48px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
      <RowCell5 />
    </div>
  );
}

function Text4() {
  return (
    <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
      <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[16px] text-center w-full">
        <p className="leading-[1.5]">Header</p>
      </div>
    </div>
  );
}

function RowCell6() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <Text4 />
        </div>
      </div>
    </div>
  );
}

function Cell6() {
  return (
    <div className="basis-0 content-stretch flex grow h-[48px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
      <RowCell6 />
    </div>
  );
}

function RowCell7() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 size-full" />
      </div>
    </div>
  );
}

function Cell7() {
  return (
    <div className="content-stretch flex h-[48px] items-start relative shrink-0 w-[72px]" data-name="Cell">
      <RowCell7 />
    </div>
  );
}

function Header() {
  return (
    <div className="bg-white content-stretch flex items-center overflow-clip relative shrink-0 w-full" data-name="Header">
      <Cell1 />
      <Cell2 />
      <Cell3 />
      <Cell4 />
      <Cell5 />
      <Cell6 />
      <Cell7 />
    </div>
  );
}

function RowStylingDefault() {
  return (
    <div className="h-[0.001px] relative shrink-0 w-full" data-name="Row Styling / Default">
      <div className="absolute bg-white bottom-[-64px] h-[64px] left-0 right-0" data-name="Background" />
      <div className="absolute bg-[#e7e7ed] bottom-[-64px] h-px left-0 right-0" data-name="Border Bottom" />
    </div>
  );
}

function IconLeft7() {
  return (
    <div className="bg-white content-stretch flex flex-col items-center justify-center relative rounded-[2px] shrink-0" data-name="Icon Left">
      <div aria-hidden="true" className="absolute border border-[#cdced9] border-solid inset-0 pointer-events-none rounded-[2px]" />
    </div>
  );
}

function RowCell8() {
  return (
    <div className="basis-0 grow min-h-px min-w-px relative self-stretch shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <IconLeft7 />
        </div>
      </div>
    </div>
  );
}

function Cell8() {
  return (
    <div className="content-stretch flex items-start relative shrink-0 w-[48px]" data-name="Cell">
      <RowCell8 />
    </div>
  );
}

function Text9() {
  return (
    <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
      <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[14px] w-full">
        <p className="leading-[1.5]">Primary Text</p>
      </div>
    </div>
  );
}

function RowCell9() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <Text9 />
        </div>
      </div>
    </div>
  );
}

function Cell9() {
  return (
    <div className="basis-0 content-stretch flex grow h-[64px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
      <RowCell9 />
    </div>
  );
}

function Text11() {
  return (
    <div className="basis-0 content-stretch flex flex-col grow items-start min-h-px min-w-px relative shrink-0" data-name="Text">
      <div className="flex flex-col font-['Source_Sans_Pro:Regular',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#272833] text-[14px] w-full">
        <p className="leading-[1.5]">Primary Text</p>
      </div>
    </div>
  );
}

function RowCell11() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <Text11 />
        </div>
      </div>
    </div>
  );
}

function Cell11() {
  return (
    <div className="content-stretch flex h-[64px] items-start relative shrink-0 w-[214px]" data-name="Cell">
      <RowCell11 />
    </div>
  );
}

function Label1() {
  return (
    <div className="bg-white box-border content-stretch flex flex-col items-center px-[12px] py-[3px] relative rounded-[2px] shrink-0" data-name="Label">
      <div aria-hidden="true" className="absolute border border-[#89a7e0] border-solid inset-0 pointer-events-none rounded-[2px]" />
      <div className="flex flex-col font-['Source_Sans_Pro:SemiBold',_sans-serif] justify-center leading-[0] not-italic relative shrink-0 text-[#2e5aac] text-[12px] text-nowrap">
        <p className="leading-[1.5] whitespace-pre">LABEL TEXT</p>
      </div>
    </div>
  );
}

function RowCell13() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <Label1 />
        </div>
      </div>
    </div>
  );
}

function Cell13() {
  return (
    <div className="basis-0 content-stretch flex grow h-[64px] items-start min-h-px min-w-px relative shrink-0" data-name="Cell">
      <RowCell13 />
    </div>
  );
}

function IconLeft12() {
  return (
    <div className="relative shrink-0 size-[16px]" data-name="Icon Left">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 16 16">
        <g id="Icon Left">
          <g id="ellipsis-v">
            <path d={svgPaths.pb849800} fill="var(--fill-0, #6B6C7E)" />
            <path d={svgPaths.p375d900} fill="var(--fill-0, #6B6C7E)" />
            <path d={svgPaths.p2053af00} fill="var(--fill-0, #6B6C7E)" />
          </g>
        </g>
      </svg>
    </div>
  );
}

function RowCell14() {
  return (
    <div className="basis-0 grow h-full min-h-px min-w-px relative shrink-0" data-name="Row Cell">
      <div className="flex flex-row items-center justify-center overflow-clip relative size-full">
        <div className="box-border content-stretch flex gap-[8px] items-center justify-center px-[12px] py-0 relative size-full">
          <IconLeft12 />
        </div>
      </div>
    </div>
  );
}

function Cell14() {
  return (
    <div className="content-stretch flex h-[64px] items-start relative shrink-0 w-[72px]" data-name="Cell">
      <RowCell14 />
    </div>
  );
}

function Cells1() {
  return (
    <div className="content-stretch flex items-center overflow-clip relative shrink-0 w-[997px]" data-name="Cells">
      <Cell8 />
      <Cell9 />
      <Cell9 />
      <Cell11 />
      <Cell9 />
      <Cell13 />
      <Cell14 />
    </div>
  );
}

function RowMainRecomponentizeDuplicate1() {
  return (
    <div className="relative rounded-[12px] shrink-0" data-name="Row / Main (recomponentize & duplicate)">
      <div className="content-stretch flex flex-col items-start overflow-clip relative">
        <RowStylingDefault />
        <Cells1 />
      </div>
      <div aria-hidden="true" className="absolute border border-[#e7e7ed] border-solid inset-[-0.5px] pointer-events-none rounded-[12.5px]" />
    </div>
  );
}

function Table() {
  return (
    <div className="bg-white content-stretch flex flex-col items-start relative rounded-[4px] shrink-0 w-full" data-name="Table">
      <Header />
      <div className="relative rounded-[12px] shrink-0" data-name="Row / Main (recomponentize & duplicate)">
        <RowMainRecomponentizeDuplicate />
      </div>
      {[...Array(9).keys()].map((_, i) => (
        <RowMainRecomponentizeDuplicate1 key={i} />
      ))}
    </div>
  );
}

function FullTable() {
  return (
    <div className="absolute content-stretch flex flex-col gap-[25px] items-start left-[90px] top-[80px]" data-name="Full Table">
      <div className="flex flex-col font-['Work_Sans:Bold',_sans-serif] font-bold justify-center leading-[0] relative shrink-0 text-[#16145a] text-[36px] text-nowrap">
        <p className="leading-[1.25] whitespace-pre">Contacts</p>
      </div>
      <Table />
    </div>
  );
}

function PageContent() {
  return (
    <div className="absolute h-[1024px] left-[264px] overflow-clip top-0 w-[1176px]" data-name="Page Content">
      <FullTable />
    </div>
  );
}

export default function Page() {
  return (
    <div className="bg-white overflow-clip relative rounded-[16px] shadow-[0px_12px_44px_0px_rgba(0,0,0,0.04)] size-full" data-name="Page">
      <div className="absolute bg-[#16145a] bottom-0 left-0 overflow-clip top-0 w-[264px]" data-name="Side Nav">
        <SideNav />
      </div>
      <PageContent />
    </div>
  );
}