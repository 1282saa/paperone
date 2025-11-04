import React from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

export const MarkdownTest = () => {
  const testMarkdown = `
# 테스트 제목

이것은 일반적인 텍스트입니다.

## 표 테스트

| 구분 | 내용 | 비고 |
|------|------|------|
| 목표 | 시장 확대 | 중요 |
| 전략 | 마케팅 강화 | 우선순위 |
| 예산 | 1억원 | 2024년 |

위에 표가 제대로 렌더링되어야 합니다.

## 목록 테스트

- 첫 번째 항목
- 두 번째 항목
- 세 번째 항목

**굵은 텍스트**와 *기울임 텍스트*도 테스트합니다.
`;

  return (
    <div className="p-8 bg-white rounded-lg max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-6 text-[#111111]">Markdown 렌더링 테스트</h1>

      <div className="grid grid-cols-2 gap-8">
        {/* 원본 마크다운 */}
        <div>
          <h2 className="text-lg font-semibold mb-4 text-[#111111]">원본 마크다운</h2>
          <pre className="bg-[#f1f3f5] p-4 rounded-lg text-sm overflow-auto">
            {testMarkdown}
          </pre>
        </div>

        {/* 렌더링된 결과 */}
        <div>
          <h2 className="text-lg font-semibold mb-4 text-[#111111]">렌더링 결과</h2>
          <div className="border border-[#e0e0e0] p-4 rounded-lg">
            <ReactMarkdown
              remarkPlugins={[remarkGfm]}
              components={{
                table: ({node, ...props}) => (
                  <table className="w-full border-collapse border border-[#e0e0e0] rounded-lg overflow-hidden my-4" {...props} />
                ),
                thead: ({node, ...props}) => (
                  <thead className="bg-[#f8f9fa]" {...props} />
                ),
                tbody: ({node, ...props}) => (
                  <tbody {...props} />
                ),
                tr: ({node, ...props}) => (
                  <tr className="border-b border-[#e0e0e0] hover:bg-[#f8f9fa] transition-colors" {...props} />
                ),
                th: ({node, ...props}) => (
                  <th className="border border-[#e0e0e0] px-4 py-3 text-left font-semibold text-[#333] bg-[#f1f3f5]" {...props} />
                ),
                td: ({node, ...props}) => (
                  <td className="border border-[#e0e0e0] px-4 py-3 text-[#111111]" {...props} />
                ),
                h1: ({node, ...props}) => (
                  <h1 className="text-2xl font-bold text-[#111111] mt-6 mb-4 pb-2 border-b-2 border-[#00c288]" {...props} />
                ),
                h2: ({node, ...props}) => (
                  <h2 className="text-xl font-semibold text-[#111111] mt-5 mb-3" {...props} />
                ),
                ul: ({node, ...props}) => (
                  <ul className="list-disc list-inside my-3 space-y-1" {...props} />
                ),
                li: ({node, ...props}) => (
                  <li className="text-[#111111] ml-2" {...props} />
                ),
                p: ({node, ...props}) => (
                  <p className="my-2 leading-relaxed text-[#111111]" {...props} />
                ),
                strong: ({node, ...props}) => (
                  <strong className="font-semibold text-[#111111]" {...props} />
                ),
                em: ({node, ...props}) => (
                  <em className="italic text-[#111111]" {...props} />
                )
              }}
            >
              {testMarkdown}
            </ReactMarkdown>
          </div>
        </div>
      </div>
    </div>
  );
};